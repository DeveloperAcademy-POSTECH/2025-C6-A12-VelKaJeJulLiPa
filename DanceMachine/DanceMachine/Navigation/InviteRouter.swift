//
//  InviteRouter.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/26/25.
//

import Foundation
import Combine

/// 초대(유니버설 링크)를 수신하고 검증/수락까지 처리하는 라우터.
/// - 역할:
///   1) 앱으로 들어온 URL에서 초대 토큰 추출
///   2) 초대 수락 트랜잭션 실행(Firestore)
///   3) 현재 팀스페이스 갱신 및 화면 리로드 트리거(`lastInviteAcceptedAt`)
final class InviteRouter: ObservableObject {
    /// 초대 수락이 완료된 시각(뷰에서 `.onChange`로 리로드 트리거로 사용)
    @Published var lastInviteAcceptedAt = Date.distantPast

    /// 들어온 URL에서 초대 토큰을 추출합니다.
    /// - Parameter url: 앱으로 전달된 유니버설 링크(또는 지원 URL)
    /// - Returns: `token` 값(없으면 `nil`)
    private func extractToken(from url: URL) -> String? {
        print("➡️ [InviteRouter] 들어온 URL:", url.absoluteString)

        // TODO: 하드 코딩 제거
        // Universal Links (Firebase Hosting 기본/커스텀 도메인 대응)
        if url.scheme == "https",
           (url.host == "dancemachine-5243b.web.app" || url.host == "app.dancemachine.com"),
           url.path == "/invite" {
            let token = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "token" })?.value
            print("🧩 [InviteRouter] 추출한 토큰(https):", token ?? "nil")
            return token
        }

        print("❓ [InviteRouter] 지원하지 않는 URL 패턴")
        return nil
    }

    /// 외부에서 전달된 URL을 처리합니다. (Scene/SwiftUI의 onContinueUserActivity 등에서 호출)
    /// - Parameter url: 유니버설 링크 URL
    @MainActor
    func handleIncoming(url: URL) {
        guard let token = extractToken(from: url) else {
            print("❗️ [InviteRouter] 토큰을 찾지 못했습니다. url=\(url.absoluteString)")
            return
        }
        Task { await accept(token: token) }
    }

    /// 초대 토큰을 Firestore에서 검증/수락하고 현재 팀스페이스를 갱신합니다.
    /// - Parameter token: 초대 토큰
    @MainActor
    private func accept(token: String) async {
        do {
            print("🚀 [InviteRouter] 초대 수락 시작. token:", token)
            let userId = MockData.userId
            let teamspaceId = try await InviteAcceptService().acceptInvite(token: token, currentUserId: userId)
            print("✅ [InviteRouter] 초대 수락 성공. teamspaceId:", teamspaceId)

            let teamspace: Teamspace = try await FirestoreManager.shared.get(teamspaceId, from: .teamspace)
            FirebaseAuthManager.shared.currentTeamspace = teamspace
            print("🔧 [InviteRouter] 현재 팀스페이스 갱신 완료:", teamspace.teamspaceId)

            self.lastInviteAcceptedAt = Date()
            print("🔁 [InviteRouter] 리로드 트리거 갱신(lastInviteAcceptedAt):", self.lastInviteAcceptedAt)
        } catch {
            print("❌ [InviteRouter] 초대 수락 실패:", error.localizedDescription)
        }
    }
}
