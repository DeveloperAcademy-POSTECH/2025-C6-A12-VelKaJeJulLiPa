//
//  CollectionType.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/30/25.
//

import Foundation

enum CollectionType: String {
    // MARK: - 메인 컬렉션
    case users = "users"
    case teamspace = "teamspace"
    case project = "project"
    case tracks = "tracks"
    case video = "video"
    case feedback = "feedback"
    case notification = "notification"
    case report = "report"
    case invites = "invites"
    
    // MARK: - 서브 컬렉션
    case userTeamspace = "user_teamspace" // users 서브 컬렉션
    case blocks = "blocks" // users 서브 컬렉션
    case members = "members" // teamspace 서브 컬렉션
    case section = "section" // tracks 서브 컬렉션
    case track = "track" // section 서브 컬렉션의 서브 컬렉션
    case reply = "reply" // feedback 서브 컬렉션
}
