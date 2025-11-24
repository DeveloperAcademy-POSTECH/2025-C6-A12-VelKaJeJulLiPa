//
//  InviteRouter.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/26/25.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

/// 초대(유니버설 링크)를 수신하고 검증/수락까지 처리하는 라우터.
/// - 역할:
///   1) 앱으로 들어온 URL에서 초대 토큰 추출
///   2) 인증이 완료되면 초대 수락 트랜잭션 실행(Firestore)
///   3) 현재 팀스페이스 갱신 및 화면 리로드 트리거(`lastInviteAcceptedAt`)
@MainActor
final class InviteRouter: ObservableObject {
  @Published var lastInviteAcceptedAt = Date.distantPast
  @Published private(set) var isProcessing = false
  
  private var pendingToken: String?
  
  private(set) var invitedTeamspaceName: String?
  
  // MARK: - URL 수신 처리
  func handleIncoming(url: URL) {
    guard let token = extractToken(from: url) else {
      print("❗️[InviteRouter] 토큰을 찾지 못했습니다:", url.absoluteString)
      return
    }
    
    private var pendingToken: String?
    
    // MARK: - URL 수신 처리
    func handleIncoming(url: URL) {
        guard let token = extractToken(from: url) else {
            print("❗️[InviteRouter] 토큰을 찾지 못했습니다:", url.absoluteString)
            return
        }
        
        // 인증이 완료되어 있다면 즉시 진행, 아니면 보류
        if isReadyForAccept() {
            Task { await accept(token: token) }
        } else {
            print("⏸️[InviteRouter] 인증 전 → 초대 토큰 보류")
            pendingToken = token
        }
    }
    
    do {
      guard let userId = FirebaseAuthManager.shared.userInfo?.userId, !userId.isEmpty else {
        print("❌[InviteRouter] userId 비어있음 → Firestore 접근 중단")
        return
      }
      
      print("🚀[InviteRouter] 초대 수락 시도. token:", token, "userId:", userId)
      let teamspaceId = try await InviteAcceptService().acceptInvite(token: token, currentUserId: userId)
      print("✅[InviteRouter] 초대 수락 성공. teamspaceId:", teamspaceId)
      
      let teamspace: Teamspace = try await FirestoreManager.shared.get(teamspaceId, from: .teamspace)
      FirebaseAuthManager.shared.currentTeamspace = teamspace
      print("🔧[InviteRouter] currentTeamspace 갱신:", teamspace.teamspaceId)
      
      // 여기 추가: lastAccessedTeamspaceId를 초대된 팀으로 갱신
      UserDefaults.standard.set(
        teamspaceId,
        forKey: AppStorageKey.lastAccessedTeamspaceId.rawValue
      )
      print("💾[InviteRouter] lastAccessedTeamspaceId 저장:", teamspaceId)
      
      self.lastInviteAcceptedAt = Date()
      self.invitedTeamspaceName = teamspace.teamspaceName
      print("🔁[InviteRouter] lastInviteAcceptedAt 갱신:", self.lastInviteAcceptedAt)
    } catch {
      print("❌[InviteRouter] 초대 수락 실패:", error)
    }
    
    // MARK: - 준비 상태 체크
    private func isReadyForAccept() -> Bool {
        FirebaseAuthManager.shared.authenticationState == .authenticated &&
        (FirebaseAuthManager.shared.userInfo?.userId.isEmpty == false)
    }
    
    // MARK: - 초대 수락
    private func accept(token: String) async {
        if isProcessing { return }
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            guard let userId = FirebaseAuthManager.shared.userInfo?.userId, !userId.isEmpty else {
                print("❌[InviteRouter] userId 비어있음 → Firestore 접근 중단")
                return
            }
            
            print("🚀[InviteRouter] 초대 수락 시도. token:", token, "userId:", userId)
            let teamspaceId = try await InviteAcceptService().acceptInvite(token: token, currentUserId: userId)
            print("✅[InviteRouter] 초대 수락 성공. teamspaceId:", teamspaceId)
            
            let teamspace: Teamspace = try await FirestoreManager.shared.get(teamspaceId, from: .teamspace)
            FirebaseAuthManager.shared.currentTeamspace = teamspace
            print("🔧[InviteRouter] currentTeamspace 갱신:", teamspace.teamspaceId)
            
            self.lastInviteAcceptedAt = Date()
            print("🔁[InviteRouter] lastInviteAcceptedAt 갱신:", self.lastInviteAcceptedAt)
        } catch {
            print("❌[InviteRouter] 초대 수락 실패:", error)
        }
    }
    
    // MARK: - Token 추출
    private func extractToken(from url: URL) -> String? {
        print("➡️[InviteRouter] 들어온 URL:", url.absoluteString)
        
        // 1) Universal Link (https)
        if url.scheme == "https" {
            let allowedHosts = ["dancemachine-5243b.web.app", "app.dancemachine.com"]
            if let host = url.host, allowedHosts.contains(host),
               url.path == "/invite" {
                let token = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "token" })?.value
                print("🧩[InviteRouter] (https) 토큰 추출:", token ?? "nil")
                return token
            }
        }
        
        // 2) Custom Scheme (dancemachine://invite?token=...)
        if url.scheme == "dancemachine", url.host == "invite" {
            let token = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "token" })?.value
            print("🧩[InviteRouter] (scheme) 토큰 추출:", token ?? "nil")
            return token
        }
        
        print("❓[InviteRouter] 지원하지 않는 URL 패턴")
        return nil
    }
}
