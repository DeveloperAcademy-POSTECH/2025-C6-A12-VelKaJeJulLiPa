//
//  NavigationDestination.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import Foundation


enum AuthRoute: Hashable {
  case login
}


enum MainRoute: Hashable {
  case home
  case inbox(InboxRoute)
  case mypage(MyPageRoute)

  case teamspace(TeamspaceRoute)
  case project(ProjectRoute)

  case video(VideoRoute)
  
  // MARK: 플로팅 버튼 글래스 모피즘 적용 테스트를 위한 분기 코드
  // 전체 기능 구현 이후에 화면 분기처리로 상단 rootView에서 버튼 관리
  //    var floatingButtonType: FloatingButtonType {
  //      switch self {
  //      case .home:
  //        return .none
  //      case .inbox:
  //        return .none
  //      case .mypage:
  //        return .none
  //      case .teamspace:
  //        return .none
  //      case .video:
  //        return .videoList
  //      }
  //    }
}

enum ProjectRoute: Hashable {
  case create
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
  case editName
  case privacyPolicy
  case termsOfUse
  case accountSetting
  case appMaker
}

enum VideoRoute: Hashable {
  case list(tracksId: String, sectionId: String, trackName: String)
  case section(section: [Section], tracksId: String, trackName: String, sectionId: String)
  case play(videoId: String, videoTitle: String, videoURL: String)
}

enum FloatingButtonType {
  case videoList
  case none
}

typealias AuthRouter = NavigationRouter<AuthRoute>
typealias MainRouter = NavigationRouter<MainRoute>
