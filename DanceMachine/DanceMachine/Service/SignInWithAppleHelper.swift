//
//  SignInWithAppleHelper.swift
//  DanceMachine
//
//  Created by Paidion on 10/12/25.
//

import Foundation
import SwiftUI
import AuthenticationServices
import CryptoKit


/// 애플 로그인 로직을 담당
final class SignInAppleHelper: NSObject {
  
  private var currentNonce: String?
  private var completionHandler: ((Result<SignInWithAppleResult, Error>) -> Void)? = nil
  
  func startSignInWithAppleFlow() async throws -> SignInWithAppleResult {
    try await withCheckedThrowingContinuation { continuation in
      self.startSignInWithAppleFlow { result in
        switch result {
        case .success(let signInAppleResult):
          continuation.resume(returning: signInAppleResult)
          return
        case .failure(let error):
          continuation.resume(throwing: error)
          return
        }
      }
    }
  }
  
  func startSignInWithAppleFlow(viewController: UIViewController? = nil, completion: @escaping (Result<SignInWithAppleResult, Error>) -> Void) {
    guard let topVC = viewController ?? UIApplication.topViewController() else {
      completion(.failure(SignInWithAppleError.noViewController))
      return
    }
    
    let nonce = randomNonceString()
    currentNonce = nonce
    completionHandler = completion
    
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let request = appleIDProvider.createRequest()
    request.requestedScopes = [.fullName, .email]
    request.nonce = sha256(nonce)
    
    let authorizationController = ASAuthorizationController(authorizationRequests: [request])
    authorizationController.delegate = self
    authorizationController.presentationContextProvider = topVC
    authorizationController.performRequests()
  }
  
  func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    var randomBytes = [UInt8](repeating: 0, count: length)
    let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    if errorCode != errSecSuccess {
      fatalError("Unable to generate nonce.")
    }
    
    let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    return String(randomBytes.map { charset[Int($0) % charset.count] })
  }
  
  
  func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    return hashedData.map { String(format: "%02x", $0) }.joined()
  }

  /// JWT에서 transfer_sub 클레임 추출
  /// - Parameter idToken: Apple Identity Token (JWT)
  /// - Returns: transfer_sub 값 (존재하지 않으면 nil)
  private func extractTransferSub(from idToken: String) -> String? {
    // JWT는 header.payload.signature 형식
    let segments = idToken.components(separatedBy: ".")
    guard segments.count == 3 else {
      print("⚠️ [SignInAppleHelper] Invalid JWT format")
      return nil
    }

    let payloadSegment = segments[1]

    // Base64URL 디코딩
    var base64 = payloadSegment
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")

    // Padding 추가
    let remainder = base64.count % 4
    if remainder > 0 {
      base64.append(String(repeating: "=", count: 4 - remainder))
    }

    guard let payloadData = Data(base64Encoded: base64) else {
      print("⚠️ [SignInAppleHelper] Failed to decode payload")
      return nil
    }

    // JSON 파싱
    do {
      let json = try JSONSerialization.jsonObject(with: payloadData, options: [])
      guard let payload = json as? [String: Any] else {
        print("⚠️ [SignInAppleHelper] Invalid payload format")
        return nil
      }

      // transfer_sub 추출
      if let transferSub = payload["transfer_sub"] as? String {
        return transferSub
      }

      return nil
    } catch {
      print("⚠️ [SignInAppleHelper] JSON parsing error: \(error)")
      return nil
    }
  }

  private enum SignInWithAppleError: LocalizedError {
    case noViewController
    case invalidCredential
    case badResponse
    case unableToFindNonce
    case failedToStartFlow
    
    var errorDescription: String? {
      switch self {
      case .noViewController:
        return "Could not find top view controller."
      case .invalidCredential:
        return "Invalid sign in credential."
      case .badResponse:
        return "Apple Sign In had a bad response."
      case .unableToFindNonce:
        return "Apple Sign In token expired."
      case .failedToStartFlow:
        return "Apple SIgn In failed."
      }
    }
  }
  
}


/// 애플 로그인 성공 및 실패 분기처리
extension SignInAppleHelper: ASAuthorizationControllerDelegate {
  
  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    print("🍎 [SignInAppleHelper] Apple Sign-In 성공 콜백")

    guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
      print("❌ [SignInAppleHelper] AppleIDCredential 변환 실패")
      completionHandler?(.failure(SignInWithAppleError.invalidCredential))
      return
    }

    guard let appleIDToken = appleIDCredential.identityToken else {
      print("❌ [SignInAppleHelper] identityToken 없음")
      completionHandler?(.failure(SignInWithAppleError.badResponse))
      return
    }

    guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
      print("❌ [SignInAppleHelper] identityToken UTF8 변환 실패")
      completionHandler?(.failure(SignInWithAppleError.badResponse))
      return
    }

    guard let nonce = currentNonce else {
      print("❌ [SignInAppleHelper] currentNonce 없음")
      completionHandler?(.failure(SignInWithAppleError.unableToFindNonce))
      return
    }

    // Apple User Identifier (디버깅용 - 이 값이 바뀌는지 추적)
    let appleUserId = appleIDCredential.user
    print("📱 [SignInAppleHelper] Apple User ID: \(appleUserId)")

    let fullName = appleIDCredential.fullName
    let email = appleIDCredential.email

    // 중요: email과 fullName은 최초 로그인 시에만 제공됨
    if let email = email {
      print("📧 [SignInAppleHelper] Email 제공됨: \(email)")
    } else {
      print("⚠️ [SignInAppleHelper] Email 제공 안됨 (재로그인 또는 이메일 숨김)")
    }

    if let fullName = fullName {
      print("👤 [SignInAppleHelper] FullName 제공됨: \(fullName)")
    } else {
      print("⚠️ [SignInAppleHelper] FullName 제공 안됨 (재로그인)")
    }

    // transfer_sub 추출 (App Transfer 시에만 존재)
    let transferSub = extractTransferSub(from: idTokenString)

    if let transferSub = transferSub {
      print("🔄 [SignInAppleHelper] Transfer Sub 감지: \(transferSub)")
      print("   → App Transfer 감지! Migration 필요")
    } else {
      print("ℹ️ [SignInAppleHelper] Transfer Sub 없음 (정상 로그인)")
    }

    let tokens = SignInWithAppleResult(
      token: idTokenString,
      nonce: nonce,
      appleIDCredential: appleIDCredential,
      fullName: fullName,
      email: email,
      appleUserId: appleUserId,
      transferSub: transferSub
    )

    print("✅ [SignInAppleHelper] Apple Sign-In 완료")
    completionHandler?(.success(tokens))
  }
  
  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    print("❌ [SignInAppleHelper] Apple Sign-In 실패: \(error.localizedDescription)")
    completionHandler?(.failure(error))
  }
}


/// 애플 로그인 후 애플이 제공해주는 정보
struct SignInWithAppleResult {
  let token: String
  let nonce: String
  let appleIDCredential: ASAuthorizationAppleIDCredential
  let fullName: PersonNameComponents?
  let email: String?
  let appleUserId: String  // Apple User Identifier (디버깅 및 추적용)
  let transferSub: String?  // App Transfer 시 이전 identifier (Migration용)
}

///  애플 로그인 버튼
struct SignInWithAppleButtonViewRepresentable: UIViewRepresentable {
  
  let type: ASAuthorizationAppleIDButton.ButtonType
  let style: ASAuthorizationAppleIDButton.Style
  
  func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
    ASAuthorizationAppleIDButton(authorizationButtonType: type, authorizationButtonStyle: style)
  }
  
  func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
  }
  
}
