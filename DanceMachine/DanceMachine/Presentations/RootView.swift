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

  @AppStorage("hasShownAccountRecoveryAlert") private var hasShownAccountRecoveryAlert = false
  @State private var showAccountRecoveryAlert = false

  var body: some View {
    NavigationStack(path: $router.destination) {
      TabView(selection: $tabcase) {
        ForEach(TabCase.allCases) { tab in
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
    .onAppear {
      // 이메일이 Unknown이거나 이름이 비어있거나 Unknown인 사용자에게 한 번만 알림 표시
      if !hasShownAccountRecoveryAlert {
        let currentEmail = FirebaseAuthManager.shared.userInfo?.email ?? "Unknown"
        let currentName = FirebaseAuthManager.shared.userInfo?.name ?? "Unknown"

        let needsRecovery = currentEmail == "Unknown" || currentName.isEmpty || currentName == "Unknown"

        if needsRecovery {
          DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showAccountRecoveryAlert = true
            hasShownAccountRecoveryAlert = true
          }
        }
      }
    }
    .alert("계정 복구 안내", isPresented: $showAccountRecoveryAlert) {
      Button("확인", role: .cancel) { }
    } message: {
      Text("앱 업데이트로 계정 정보가 초기화 되신 유저분들은\n마이페이지 > 계정 복구 탭에서 복구할 수 있습니다.")
    }
  }
  
  private func tabLabel(_ tab: TabCase) -> some View {
    VStack(spacing: 8, content: {
      Image(systemName: tab.icon)

      Text(tab.localizedString)
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
      .environmentObject(InviteRouter())
  }
}
