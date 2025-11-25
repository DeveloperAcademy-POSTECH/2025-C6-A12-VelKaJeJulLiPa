//
//  ContentView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI
import FirebaseAuth
import SwiftData

struct HomeView: View {
  @Environment(\.cacheStore) private var cache
  @EnvironmentObject private var router: MainRouter
  @EnvironmentObject private var inviteRouter: InviteRouter
  
  @State private var homeViewModel: HomeViewModel = .init()
  @State private var projectListViewModel: ProjectListViewModel = .init()
  @State private var tracksViewModel: TracksListViewModel? = nil
  
  @State private var showInviteToastMessage: Bool = false // 초대 관련 토스트 메세지
  
  var onTrackSelect: ((Tracks) -> Void)? = nil
  
  //  init(viewModel: HomeViewModel? = nil) {
  //    // 외부에서 주입 가능, 없으면 환경값으로 생성
  //    _viewModel = State(initialValue: viewModel ?? HomeViewModel(cache: CacheStoreKey.defauOtracksViewModelltValue))
  //  }
  
  fileprivate struct Layout {
    enum CommonView {
      static let horizontalSpacing: CGFloat = 16
    }
    
    enum EmptyTeamspaceView {
      static let imageName: String = "person.2.fill"
      static let imageSize: CGFloat = 110
      static let vstackSpacing: CGFloat = 10
      static let titleText: String = "팀 스페이스를 만들어주세요."
    }
  }
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      
      VStack {
        TeamspaceTitleView(
          viewModel: homeViewModel,
          projectListViewModel: projectListViewModel,
          tracksViewModel: $tracksViewModel
        )
        .padding(.horizontal, Layout.CommonView.horizontalSpacing)
        
        Spacer().frame(height: 24)
        
        if homeViewModel.state.teamspaceState == .empty {
          emptyTeamspaceView
            .padding(.horizontal, Layout.CommonView.horizontalSpacing)
        } else {
          ProjectListView(
            homeViewModel: homeViewModel,
            projectListViewModel: projectListViewModel,
            tracksViewModel: $tracksViewModel,
            onTrackSelect : onTrackSelect
          )
        }
      }
    }
    .overlay { if homeViewModel.state.isLoading { LoadingView() } }
    .task {
      // 알림
      await homeViewModel.setupNotificationAuthorizationIfNeeded()
    }
    .task {
      // 데이터 로딩
      if ProcessInfo.isRunningInPreviews { return } // 프리뷰 전용
      
      guard FirebaseAuthManager.shared.user != nil else {
        print("🚫 HomeView.task 중간: 로그인 상태 아님")
        return
      }
      
      homeViewModel.state.isLoading = true
      
      defer { homeViewModel.state.isLoading = false }
      
      print("🔥 HomeViewLoding...")
      do {
        if homeViewModel.cacheStore == nil { homeViewModel.setCacheStore(cache) }
        await homeViewModel.onAppear()
        
        guard let userId = FirebaseAuthManager.shared.user?.uid else {
          return
        }
        
        try await NotificationManager.shared.refreshBadge(for: userId)
      } catch {
        
      }
    }
    // 초대 링크 관련
    .onChange(of: inviteRouter.lastInviteAcceptedAt) {
      if ProcessInfo.isRunningInPreviews { return }
      Task {
        print("🎉 초대 링크 성공! 화면에 반영합니다.")
        await homeViewModel.onAppear()
        self.showInviteToastMessage = true
      }
    }
    .toast(
      isPresented: $showInviteToastMessage) {
        ToastView(text: "\(inviteRouter.invitedTeamspaceName ?? "")팀에 입장하셨습니다.", icon: .check)
      }
  }
  
  // MARK: - 팀 스페이스가 비어져있을때 보이는 뷰
  private var emptyTeamspaceView: some View {
    VStack(spacing: Layout.EmptyTeamspaceView.vstackSpacing) {
      Spacer()
      Image(systemName: Layout.EmptyTeamspaceView.imageName)
        .font(.system(size: Layout.EmptyTeamspaceView.imageSize))
        .foregroundStyle(Color.fillAlternative)
        .frame(maxWidth: .infinity)
      Text(Layout.EmptyTeamspaceView.titleText)
        .font(.headline2Medium)
        .foregroundStyle(Color.labelAssitive)
      Spacer()
    }
  }
}

#Preview("HomeView · 프리뷰 목 데이터") {
  NavigationStack {
    HomeView()
      .environmentObject(MainRouter())
      .environmentObject(InviteRouter())
  }
}

