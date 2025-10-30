//
//  TeamspaceMockData.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/31/25.
//

import Foundation

#if DEBUG
// MARK: - 팀 스페이스 MockData
extension Teamspace {
    static let TeamspaceMockData: [Teamspace] = [
        .init(teamspaceId: UUID(), ownerId: "", teamspaceName: "벨카제줄리파"),
        .init(teamspaceId: UUID(), ownerId: "", teamspaceName: "라면먹고싶다"),
        .init(teamspaceId: UUID(), ownerId: "", teamspaceName: "일본가고싶다"),
        .init(teamspaceId: UUID(), ownerId: "", teamspaceName: "대학교xx동아리"),
        .init(teamspaceId: UUID(), ownerId: "", teamspaceName: "춤이란무엇인가")
    ]
}
#endif
