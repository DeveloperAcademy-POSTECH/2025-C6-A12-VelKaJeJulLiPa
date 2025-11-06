//
//  RootView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI

struct RootView: View {

  @EnvironmentObject private var router: MainRouter
  @Environment(TabRouter.self) private var tabRouter
  @State private var isProjectExpanded = false

  // 현재 탭에 따른 커스텀 액션 표시 여부
  private var shouldShowCustomAction: Bool {
    tabRouter.currentTab == .home
  }

  // 커스텀 액션 아이콘 (expand 상태에 따라)
  private var customActionIcon: String {
    isProjectExpanded ? "music.note.list" : "folder.badge.plus"
  }

  // 커스텀 액션 실행
  private func handleCustomAction() {
    if isProjectExpanded {
      // 프로젝트 펼쳐진 상태: 곡 생성
      NotificationCenter.default.post(name: .showCreateTrack, object: nil)
    } else {
      // 프로젝트 접힌 상태: 프로젝트 생성
      NotificationCenter.default.post(name: .showCreateProject, object: nil)
    }
  }

  var body: some View {
    TabView(selection: Binding(
      get: { tabRouter.currentTab },
      set: { newValue in
        if newValue == .custom {
          handleCustomAction()
        } else {
          tabRouter.switchTab(to: newValue)
          router.destination.removeAll()
        }
      }
    )) {
      // 일반 탭들
      Tab(value: .home) {
        NavigationStack(path: $router.destination) {
          tabView(tab: .home)
            .navigationDestination(for: MainRoute.self) { destination in
              MainNavigationRoutingView(destination: destination)
                .environmentObject(router)
            }
        }
      } label: {
        tabLabel(.home)
      }

      Tab(value: .inbox) {
        NavigationStack(path: $router.destination) {
          tabView(tab: .inbox)
            .navigationDestination(for: MainRoute.self) { destination in
              MainNavigationRoutingView(destination: destination)
                .environmentObject(router)
            }
        }
      } label: {
        tabLabel(.inbox)
      }

      Tab(value: .myPage) {
        NavigationStack(path: $router.destination) {
          tabView(tab: .myPage)
            .navigationDestination(for: MainRoute.self) { destination in
              MainNavigationRoutingView(destination: destination)
                .environmentObject(router)
            }
            .tag(tab)
          },
          label: {
            tabLabel(tab)
          })
        .badge(tab == .inbox ? notificationManager.unreadNotificationCount : 0)
        }
      } label: {
        tabLabel(.myPage)
      }

      // 커스텀 액션 탭 (홈에서만 표시)
      if shouldShowCustomAction {
        Tab(value: .custom, role: .search) {
          Color.clear
        } label: {
          Image(systemName: customActionIcon)
        }
      }
    }
    .tint(Color.black)
    // 곡 리스트 열려있을 때 (곡 생성 버튼)
    .onReceive(NotificationCenter.default.publisher(for: .projectDidExpand)) { _ in
      isProjectExpanded = true
    }
    // 곡 리스트 닫혀있을 때 (프로젝트 생성 버튼)
    .onReceive(NotificationCenter.default.publisher(for: .projectDidCollapse)) { _ in
      isProjectExpanded = false
    }
    // 곡 리스트 열린 상태로 팀스페이스 변경시 액션버튼 상태 업데이트
    .onChange(of: FirebaseAuthManager.shared.currentTeamspace?.teamspaceId) { oldValue, newValue in
      self.isProjectExpanded = false
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
    Group {
      switch tab {
      case .home:
        MainNavigationRoutingView(
          destination: .home
        )
      case .inbox:
        MainNavigationRoutingView(
          destination: .inbox(.list)
        )
      case .myPage:
        MainNavigationRoutingView(
          destination: .mypage(.profile)
        )
      case .custom:
        EmptyView()
      }
    }
    .environmentObject(router)
  }
}

#Preview {
  NavigationStack {
    RootView()
      .environmentObject(MainRouter())
  }
}
