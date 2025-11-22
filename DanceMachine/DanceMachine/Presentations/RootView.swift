//
//  RootView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI

struct RootView: View {
  
  @EnvironmentObject private var router: MainRouter
  @State var tabcase: TabCase = .home
  @StateObject private var notificationManager = NotificationManager.shared
  
  var body: some View {
    NavigationStack(path: $router.destination) {
      TabView(selection: $tabcase) {
        ForEach(TabCase.allCases, id: \.rawValue) { tab in
          Tab(value: tab) {
            tabView(tab: tab)
              .tag(tab)
          } label: { tabLabel(tab) }
            .badge(
              tab == .inbox ? notificationManager.unreadNotificationCount : 0
            )
        }
      }
      .navigationDestination(for: MainRoute.self) { destination in
        MainNavigationRoutingView(destination: destination)
          .environmentObject(router)
      }
    }
    .preferredColorScheme(.dark)
    .onChange(of: tabcase) { oldValue, newValue in
      if oldValue != newValue {
        router.destination.removeAll()
      }
    }
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
    switch tab {
    case .home:
      MainNavigationRoutingView(
        destination: .home
      )
      .environmentObject(router)
    case .inbox:
      MainNavigationRoutingView(
        destination: .inbox(.list)
      )
      .environmentObject(router)
    case .myPage:
      MainNavigationRoutingView(
        destination: .mypage(.profile)
      )
      .environmentObject(router)
    }
  }
}

#Preview {
  NavigationStack {
    RootView()
      .environmentObject(MainRouter())
  }
}
