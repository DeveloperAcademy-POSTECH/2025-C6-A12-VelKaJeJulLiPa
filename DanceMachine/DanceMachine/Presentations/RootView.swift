//
//  RootView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI

struct RootView: View {
    
    @EnvironmentObject private var router: NavigationRouter
    @State var tabcase: TabCase = .home
    
    var body: some View {
        NavigationStack(path: $router.destination, root: {
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
            .navigationDestination(for: NavigationDestination.self, destination: { destination in
                NavigationRoutingView(destination: destination)
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
                HomeView()
            case .inbox:
                InboxView()
            case .myPage:
                MyPageView()
            }
        }
        .environmentObject(router)
    }
}

#Preview {
    RootView()
}
