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
                case .editName:
                    EditNameView()
                case .privacyPolicy:
                    PrivacyPolicyView()
                case .termsOfUse:
                    TermsOfUseView()
                case .accountSetting:
                    AccountSettingView()
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
            case .project(let route):
                switch route {
                case .create:
                    CreateProjectView()
                }
            case .video(let route):
                switch route {
                case .list(let tracksId, let sectionId, let trackName):
                  VideoListView(
                    tracksId: tracksId,
                    sectionId: sectionId,
                    trackName: trackName
                  )
                case .section(let section, let tracksId, let trackName, let sectionId):
                  SectionEditView(
                    sections: section,
                    tracksId: tracksId,
                    trackName: trackName,
                    sectionId: sectionId
                  )
                case .play(let videoId, let videoTitle, let videoURL, let teamspaceId, let authorId):
                  VideoView(
                    teamspaceId: teamspaceId,
                    authorId: authorId,
                    videoId: videoId,
                    videoTitle: videoTitle,
                    videoURL: videoURL
                  )
                case .play(let videoId, let videoTitle, let videoURL, let teamspaceId, let authorId):
                  VideoView(
                    teamspaceId: teamspaceId,
                    authorId: authorId,
                    videoId: videoId,
                    videoTitle: videoTitle,
                    videoURL: videoURL
                  )
                }
            }
        }
        .hideBackButton()
        .dismissKeyboardOnTap()
        .environmentObject(router)
    }
}
