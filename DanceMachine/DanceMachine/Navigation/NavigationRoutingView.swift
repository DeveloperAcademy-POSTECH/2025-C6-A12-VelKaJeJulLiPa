//
//  NavigationRoutingView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI

struct NavigationRoutingView: View {
    @EnvironmentObject var router: NavigationRouter
    @State var destination: NavigationDestination
    
    var body: some View {
        Group {
            switch destination {
            case .homeView:
                HomeView() // FIXME: - 임시
            case .sectionEditView(let section, let tracksId, let trackName):
              SectionEditView(
                sections: section,
                tracksId: tracksId,
                trackName: trackName
              )
            }
        }
        .hideBackButton()
        .dismissKeyboardOnTap()
        .environmentObject(router)
    }
}
