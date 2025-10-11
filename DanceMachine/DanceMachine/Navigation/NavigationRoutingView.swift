//
//  NavigationRoutingView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI

struct NavigationRoutingView: View {
    @EnvironmentObject var router: NavigationRouter
    @State var destination: AppRoute
    
    var body: some View {
        Group {
            switch destination {
            case .home:
                HomeView()
            case .inbox(let route):
                switch route {
                case .list:
                    InboxView()
                }
            case .mypage(let route):
                switch route {
                case .profile:
                    MyPageView()
                }
            case .teamspace(let route):
                switch route {
                case .list(let teamspace):
                    TeamspaceListView(teamspaces: teamspace)
                case .create:
                    CreateTeamspaceView()
                }
            }
        }
        .hideBackButton()
        .dismissKeyboardOnTap()
        .environmentObject(router)
    }
}
