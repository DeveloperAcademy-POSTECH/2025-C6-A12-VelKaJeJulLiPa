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
    case project(ProjectRoute)
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
}

