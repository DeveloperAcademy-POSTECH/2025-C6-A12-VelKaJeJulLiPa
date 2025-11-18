//
//  TeamspaceTitleView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/28/25.
//

import SwiftUI

struct TeamspaceTitleView: View {
  @EnvironmentObject private var router: MainRouter
  
  @Bindable var viewModel: HomeViewModel
  
  fileprivate struct Layout {
    enum EmptyTeamspaceViewLayout {
      static let hstackSpacing: CGFloat = 8
      static let titleText: String = "팀 스페이스를 생성하세요"
      static let imageName: String = "chevron.right"
      static let imageFontSize: CGFloat = 15
    }
    
    enum NonEmptyTeamspaceViewLayout {
      static let hstackSpacing: CGFloat = 8
      static let titleText: String = "팀 스페이스를 생성하세요"
      static let teamspaceEmptyTitleText: String = ""
      static let imageName: String = "chevron.right"
      static let imageFontSize: CGFloat = 17
    }
  }
  
  var body: some View {
    Group {
      switch viewModel.state.teamspaceState {
      case .empty:
        emptyTeamspaceView
          .frame(maxWidth: .infinity, alignment: .leading)
      case .nonEmpty:
        nonEmptyTeamspaceView
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
  
  // MARK: - 팀 스페이스가 없을 때 보이는 뷰
  private var emptyTeamspaceView: some View {
    Button {
      //      self.presentingCreateTeamspaceSheet = true
      // TODO: 기존 시트에서 네비게이션 팀 스페이스 만들기로 전환 형식으로 변경해야 함.
      // TODO: 팀 스페이스 생성하세요 할때 잘 작동되는지도 확인
    } label: {
      HStack {
        HStack(spacing: Layout.EmptyTeamspaceViewLayout.hstackSpacing) {
          Text(Layout.EmptyTeamspaceViewLayout.titleText)
            .font(.heading1Medium)
            .foregroundStyle(Color.labelStrong)
          
          Image(systemName: Layout.EmptyTeamspaceViewLayout.imageName)
            .font(.system(size: Layout.EmptyTeamspaceViewLayout.imageFontSize, weight: .semibold))
            .foregroundStyle(Color.labelStrong)
        }
      }
    }
  }
  
  // MARK: - 팀 스페이스 선택 뷰
  private var nonEmptyTeamspaceView: some View {
    HStack(spacing: 8) {
      Text(viewModel.currentTeamspace?.teamspaceName ?? Layout.NonEmptyTeamspaceViewLayout.teamspaceEmptyTitleText)
        .font(.heading1SemiBold)
        .foregroundStyle(Color.labelStrong)
      
      Spacer()
      
      Button {
        router.push(to: .teamspace(.setting))
      } label: {
        Image(systemName: Layout.NonEmptyTeamspaceViewLayout.imageName)
          .font(.system(size: Layout.NonEmptyTeamspaceViewLayout.imageFontSize, weight: .medium))
          .foregroundStyle(Color.labelStrong)
      }
      .clearGlassButtonIfAvailable()
    }
  }
}


//// MARK: - 프리뷰
//
//#Preview("팀 없을 때") {
//  ZStack {
//    Color.backgroundNormal.ignoresSafeArea()
//    
//    TeamspaceTitleView(
//      viewModel: HomeViewModel(),
//      teamspaceState: .constant(.empty),
//      presentingCreateTeamspaceSheet: .constant(false)
//    )
//    .environmentObject(MainRouter())
//  }
//}
//
//#Preview("팀 있을 때 (Mock)") {
//  PreviewTeamspaceTitleNonEmpty()
//}
//
//
//private struct PreviewTeamspaceTitleNonEmpty: View {
//  @State private var vm = HomeViewModel()
//  @State private var state: TeamspaceState = .nonEmpty
//  
//  var body: some View {
//    ZStack {
//      Color.backgroundNormal.ignoresSafeArea()
//      
//      TeamspaceTitleView(
//        viewModel: vm,
//        teamspaceState: $state,
//        presentingCreateTeamspaceSheet: .constant(false)
//      )
//      .environmentObject(MainRouter())
//      .task {
//        let mock = Teamspace(
//          teamspaceId: UUID(),
//          ownerId: "",
//          teamspaceName: "댄스머신 팀"
//        )
//        
//        FirebaseAuthManager.shared.currentTeamspace = mock
//        
//        vm.teamspace.list = [mock]
//        vm.teamspace.state = .nonEmpty
//        vm.teamspace.isLoading = false
//      }
//    }
//  }
//}
//
