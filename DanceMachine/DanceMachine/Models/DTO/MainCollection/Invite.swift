//
//  Invite.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/26/25.
//

import Foundation
import FirebaseFirestore

struct Invite: Codable {
    
    let inviteId: String
    let teamspaceId: String
    let inviterId: String
    let role: String
    let token: String
    let status: Status
    let uses: Int
//    let expiresAt: Timestamp
//    let createdAt: Timestamp?
    
    
    enum CodingKeys: String, CodingKey {
        case inviteId   = "invite_id"
        case teamspaceId = "teamspace_id"
        case inviterId  = "inviter_id"
        case role
        case token
        case status
        case uses
//        case expiresAt  = "expires_at"
//        case createdAt  = "created_at"
    }

    // 초대 상태
    enum Status: String, Codable {
        case pending
        case completed
        case revoked
    }
}


extension Invite: EntityRepresentable {
    var entityName: CollectionType { .invites }
    var documentID: String { inviteId }
    
//    /// Firestore setData용 딕셔너리 (필요 시 사용)
//    var asDictionary: [String: Any] {
//        [
//            "invite_id": inviteId,
//            "teamspace_id": teamspaceId,
//            "inviter_id": inviterId,
//            "role": role,
//            "token": token,
//            "status": status.rawValue,
//            "uses": uses,
//            "expires_at": expiresAt,
//            // created_at은 서버 타임스탬프로 채우는 편이 일반적이라 여기선 넣지 않음
//        ]
//    }
}
