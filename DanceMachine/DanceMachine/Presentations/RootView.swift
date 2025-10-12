//
//  RootView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI

struct RootView: View {
    
    @EnvironmentObject private var router: NavigationRouter
    @State private var selectedTeamspace: Teamspace? // FIXME: - 적절한지 (선택된 홈 화면 팀스페이스)
    @State var tabcase: TabCase = .home
    
    var body: some View {
        NavigationStack(
            path: $router.destination,
            root: {
                TabView(selection: $tabcase, content: {
                    ForEach(TabCase.allCases, id: \.rawValue) { tab in
                        Tab(
                            value: tab,
                            content: {
                                tabView(tab: tab)
                                    .tag(tab)
                            },
                            label: {
                                tabLabel(tab)
                            })
                    }
                })
                .tint(Color.blue)
                .navigationDestination(
                    for: AppRoute.self,
                    destination: { destination in
                        NavigationRoutingView(
                            destination: destination,
                            selectedTeamspace: $selectedTeamspace
                        )
                    .environmentObject(router)
            })
        })
    }
    
    private func tabLabel(_ tab: TabCase) -> some View {
        VStack(spacing: 8, content: {
            Image(systemName: tab.icon)
            
            Text(tab.rawValue)
                .font(Font.system(size: 12))
                .foregroundStyle(Color.black)
        })
    }
    
    @ViewBuilder
    private func tabView(tab: TabCase) -> some View {
        Group {
            switch tab {
            case .home:
                NavigationRoutingView(
                    destination: .home,
                    selectedTeamspace: $selectedTeamspace
                )
            case .inbox:
                NavigationRoutingView(
                    destination: .inbox(.list),
                    selectedTeamspace: $selectedTeamspace
                )
            case .myPage:
                NavigationRoutingView(
                    destination: .mypage(.profile),
                    selectedTeamspace: $selectedTeamspace
                )
            }
        }
        .environmentObject(router)
    }
}

#Preview {
    RootView()
}
