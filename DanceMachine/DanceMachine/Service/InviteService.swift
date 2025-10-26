//
//  InviteService.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/26/25.
//

import FirebaseFirestore

/// 초대 링크 생성 서비스
/// Firestore에 초대 문서를 만들고, 공유용(유니버설 링크) URL을 생성해 반환합니다.
struct InviteService {
    
    /// 초대 링크 생성 (Firestore 문서 생성 + 공유 URL 반환)
        /// - Parameters:
        ///   - teamspaceId: 초대를 보낼 팀스페이스 ID
        ///   - inviterId: 초대를 생성한 사용자 ID
        ///   - role: 초대로 참여한 사용자의 역할 (기본값: member)
        ///   - ttlHours: 초대 링크 만료 시간(시간 단위, 기본값: 24시간)
        /// - Returns: 공유용 유니버설 링크 URL
    func createInvite(
        teamspaceId: String,
        inviterId: String,
        role: String = "member",
        ttlHours: Int = 24
    ) async throws -> URL {
        
        let token = UUID().uuidString + UUID().uuidString // TODO: token을 UUID로 만들어도 괜찮은가? 이야기
        let inviteId = UUID().uuidString

        let invite: Invite = .init(
            inviteId: inviteId,
            teamspaceId: teamspaceId,
            inviterId: inviterId,
            role: role,
            token: token,
            status: .pending,
            uses: 0
        )
        
        try await FirestoreManager.shared.createInvite(invite)
         
        print("🧪[InviteService] 초대 생성 시작")
        print("팀스페이스ID=\(teamspaceId), 초대자ID=\(inviterId), 역할=\(role), 만료시간(시간)=\(ttlHours)")
        print("생성된 inviteId=\(inviteId), token=\(token)")
        
        // 공유용 유니버설 링크(예: Firebase Hosting 도메인) 구성
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = "dancemachine-5243b.web.app"
        comps.path = "/invite"
        comps.queryItems = [ URLQueryItem(name: "token", value: token) ]
        
        guard let url = comps.url else {
            print("❌ [InviteService] URL 생성 실패")
            throw InviteError.urlBuildFailed
        }

        print("✅ [InviteService] 초대 링크 생성 완료: \(url.absoluteString)")
        return url
    }
}
