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
                case .list:
                    TeamspaceListView()
                case .create:
                    CreateTeamspaceView()
                case .setting:
                    TeamspaceSettingView()
                }
            case .video(let route):
                switch route {
                case .list(let tracksId, let sectionId, let trackName):
                  VideoListView(
                    tracksId: tracksId,
                    sectionId: sectionId,
                    trackName: trackName
                  )
                case .section(let section, let tracksId, let trackName):
                  SectionEditView(
                    sections: section,
                    tracksId: tracksId,
                    trackName: trackName
                  )
                }
            }
        }
        .hideBackButton()
        .dismissKeyboardOnTap()
        .environmentObject(router)
    }
}
