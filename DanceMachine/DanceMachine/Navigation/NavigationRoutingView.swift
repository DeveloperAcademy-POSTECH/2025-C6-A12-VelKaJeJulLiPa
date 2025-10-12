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
    
    @Binding var selectedTeamspace: Teamspace?
    
    var body: some View {
        Group {
            switch destination {
            case .home:
                HomeView(titleTeamspace: $selectedTeamspace)
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
                case .list:
                    TeamspaceListView(selected: $selectedTeamspace)
                case .create:
                    CreateTeamspaceView()
                case .setting:
                    TeamspaceSettingView()
                }
            }
        }
        .hideBackButton()
        .dismissKeyboardOnTap()
        .environmentObject(router)
    }
}
