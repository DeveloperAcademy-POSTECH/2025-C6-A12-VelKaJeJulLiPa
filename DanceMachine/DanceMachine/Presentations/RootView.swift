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
    TabView(selection: $tabcase, content: {
      ForEach(TabCase.allCases, id: \.rawValue) { tab in
        Tab(
          value: tab,
          content: {
            NavigationStack(path: $router.destination) {
              tabView(tab: tab)
                .navigationDestination(
                  for: MainRoute.self,
                  destination: { destination in
                    MainNavigationRoutingView(
                      destination: destination
                    )
                    .environmentObject(router)
                  })
            }
            .tag(tab)
          },
          label: {
            tabLabel(tab)
          })
        .badge(tab == .inbox ? notificationManager.unreadNotificationCount : 0)
      }
      //                  Tab(value: tabcase, role: .search) {
      //                    Color.clear
      //                  } label: {
      //                    Image(systemName: "plus.circle.fill")
      ////                    Text("영상 추가하기")
      //                  }
      //                  Tab(value: TabCase.myPage, role: .search) {
      //                    Image(systemName: "plus.circle.fill")
      //                  }
    })
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
