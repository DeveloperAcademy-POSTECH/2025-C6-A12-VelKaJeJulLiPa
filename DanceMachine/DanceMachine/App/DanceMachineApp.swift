//
//  DanceMachineApp.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import AuthenticationServices
import Combine

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("🔥 FirebaseApp configured")
        
        return true
    }
}

// TODO: 팀 스페이스 초대 링크 조금 확인? 필드 수정 (대충 음... 링크 만료 시간이나, 최대 인원 횟수 조정 등등)
// TODO: 링크 타고 팀 스페이스 올 때 뷰 다시 새로고침
// TODO: 링크 메세지 문구 수정도 해야함.
// TODO: 

// InviteService.swift
struct InviteService {
    struct InviteError: Error { }

    /// 초대 링크 생성 (Firestore 문서만 생성하고, 커스텀 스킴 링크 반환)
    func createInvite(teamspaceId: String,
                      inviterId: String,
                      role: String = "member",
                      ttlHours: Int = 24) async throws -> URL {
        let token = UUID().uuidString + UUID().uuidString
        let inviteId = UUID().uuidString

        let expiresAt = Timestamp(date: Date().addingTimeInterval(TimeInterval(ttlHours * 3600))) // 초대 링크 만료일자 선택 (현재 1일)

        let data: [String: Any] = [
            "teamspace_id": teamspaceId,
            "inviter_id": inviterId,
            "role": role,
            "token": token,
            "status": "pending",   // pending, completed, revoked ...
            "max_uses": 1,
            "uses": 0,
            "expires_at": expiresAt,
            "created_at": FieldValue.serverTimestamp()
        ]

        try await Firestore.firestore()
            .collection("invites")
            .document(inviteId)
            .setData(data)

        // 커스텀 스킴 링크 (Info.plist에 dancemachine:// 등록 필요)
        // 예: dancemachine://invite?token=xxxx
        var comps = URLComponents()
        comps.scheme = "dancemachine"
        comps.host   = "invite"
        comps.queryItems = [URLQueryItem(name: "token", value: token)]
        guard let url = comps.url else { throw InviteError() }
        return url
    }
}

// 간단한 라우터
final class InviteRouter: ObservableObject {
    @MainActor
    func handleIncoming(url: URL) {
        // dancemachine://invite?token=...
        guard url.scheme == "dancemachine",
              url.host == "invite",
              let token = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "token" })?.value
        else { return }

        Task {
            do {
                // 현재 로그인 사용자 ID는 기존 로직/매니저에서 가져오세요
                let userId = MockData.userId
                let teamspaceId = try await InviteAcceptService().acceptInvite(token: token, currentUserId: userId)
                // 필요하면 여기서 currentTeamspace 셋업/네비게이션 등 진행
                print("✅ Joined teamspace: \(teamspaceId)")
            } catch {
                print("❌ Invite accept failed: \(error)")
            }
        }
    }
}

@main
struct DanceMachineApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var router: NavigationRouter = .init()
    @StateObject private var authManager = FirebaseAuthManager.shared
    
    @StateObject private var inviteRouter = InviteRouter()
    
    var body: some Scene {
        WindowGroup {
            Group {
//                switch authManager.authenticationState {
//                case .unauthenticated:
//                    LoginView()
//                        .transition(.opacity)
//                    
//                case .authenticated:
//                    ZStack {
//                        if authManager.needsNameSetting {
//                            NameSettingView()
//                        } else {
                            RootView()
                                .environmentObject(router)
                                .transition(.move(edge: .trailing))
                                .environmentObject(inviteRouter)
                                .onOpenURL { url in
                                    inviteRouter.handleIncoming(url: url)
                          //      }
                      //  }
                  //  }
                  //  .animation(.easeInOut, value: authManager.needsNameSetting)
                }
            }
            .animation(.easeInOut, value: authManager.authenticationState)
        }
    }
}


// 3) 초대 수락(검증) 로직
struct InviteAcceptService {

    enum AcceptError: Int {
        case notFound = 1
        case expired
        case alreadyUsed
        case invalidStatus
        case invalidData
    }

    private func makeNSError(_ code: AcceptError, _ msg: String) -> NSError {
        NSError(domain: "InviteAcceptService",
                code: code.rawValue,
                userInfo: [NSLocalizedDescriptionKey: msg])
    }

    /// token으로 초대 검증 + 수락 처리
    /// - Returns: teamspaceId
    func acceptInvite(token: String, currentUserId: String) async throws -> String {
        let db = Firestore.firestore()

        // 1) token으로 초대 문서 조회
        let snap = try await db.collection("invites")
            .whereField("token", isEqualTo: token)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snap.documents.first else {
            throw makeNSError(.notFound, "Invite not found")
        }

        // 2) 외부에서 한 번 파싱 (선택)
        let initial = doc.data()
        guard
            let teamspaceId = initial["teamspace_id"] as? String
        else {
            throw makeNSError(.invalidData, "Invalid invite data")
        }

        // 3) 트랜잭션 (❗️ 블록 안에서는 throw 금지, errorPointer 사용)
        try await db.runTransaction({ (txn, errorPointer) -> Any? in
            do {
                // 최신 스냅샷
                let freshSnap = try txn.getDocument(doc.reference)
                guard var fresh = freshSnap.data() else {
                    errorPointer?.pointee = self.makeNSError(.notFound, "Invite not found")
                    return nil
                }

                // 필드 파싱
                let status    = (fresh["status"] as? String) ?? "pending"
                let maxUses   = (fresh["max_uses"] as? Int) ?? 1
                let uses      = (fresh["uses"] as? Int) ?? 0
                let expiresAt = (fresh["expires_at"] as? Timestamp)?.dateValue()

                // 검증
                if let exp = expiresAt, exp < Date() {
                    errorPointer?.pointee = self.makeNSError(.expired, "Invite expired")
                    return nil
                }
                if status != "pending" {
                    errorPointer?.pointee = self.makeNSError(.invalidStatus, "Invite is not pending")
                    return nil
                }
                if uses >= maxUses {
                    errorPointer?.pointee = self.makeNSError(.alreadyUsed, "Invite already used")
                    return nil
                }

                // uses 증가 + 완료 처리
                var update: [String: Any] = ["uses": uses + 1]
                if uses + 1 >= maxUses {
                    update["status"] = "completed"
                }
                txn.updateData(update, forDocument: doc.reference)

                // users/{uid}/userTeamspace/{teamspaceId}
                let userTeamRef = db.collection("users")
                    .document(currentUserId)
                    .collection("user_teamspace")
                    .document(teamspaceId)

                txn.setData([
                    "teamspace_id": teamspaceId,
                    "joined_at": FieldValue.serverTimestamp(),
                ], forDocument: userTeamRef, merge: true)

                // teamspace/{id}/members/{uid} (옵션)
                let role = (fresh["role"] as? String) ?? "member"
                let memberRef = db.collection("teamspace")
                    .document(teamspaceId)
                    .collection("members")
                    .document(currentUserId)

                txn.setData([
                    "user_id": currentUserId,
                    "joined_at": FieldValue.serverTimestamp(),
                    "role": role
                ], forDocument: memberRef, merge: true)

                return nil
            } catch {
                // 블록 안에서 throw 금지 → NSError로 변환
                errorPointer?.pointee = error as NSError
                return nil
            }
        })

        return teamspaceId
    }
}



// UIApplication+TopMost.swift
import UIKit

extension UIApplication {
    func topMostViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }.first) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topMostViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topMostViewController(base: presented)
        }
        return base
    }
}
