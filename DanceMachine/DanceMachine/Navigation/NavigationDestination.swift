//
//  NavigationDestination.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import Foundation

enum AppRoute: Hashable {
    case home
    case inbox(InboxRoute)
    case mypage(MyPageRoute)
    
    case teamspace(TeamspaceRoute)
  
    case video(VideoRoute)
  
    var floatingButtonType: FloatingButtonType {
      switch self {
      case .home:
        return .none
      case .inbox:
        return .none
      case .mypage:
        return .none
      case .teamspace:
        return .none
      case .video:
        return .videoList
      }
    }
}

enum TeamspaceRoute: Hashable {
    case list
    case create
    case setting
}

enum InboxRoute: Hashable {
    case list
}

enum MyPageRoute: Hashable {
    case profile
}

enum VideoRoute: Hashable {
    case list(tracksId: String, sectionId: String, trackName: String)
    case section(section: [Section], tracksId: String, trackName: String)
    case play(videoId: String, videoTitle: String, videoURL: String, teamspaceId: String, authorId: String)
}

enum FloatingButtonType {
  case videoList
  case none
}
