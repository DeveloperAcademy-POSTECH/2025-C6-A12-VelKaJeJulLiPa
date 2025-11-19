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
  @Bindable var projectListViewModel: ProjectListViewModel
  
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
      static let imageName: String = "person.2.badge.gearshape.fill"
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
      self.router.push(to: .teamspace(.create))
    } label: {
      HStack(spacing: Layout.EmptyTeamspaceViewLayout.hstackSpacing) {
        Group {
          Text(Layout.EmptyTeamspaceViewLayout.titleText)
            .font(.heading1SemiBold)
            .foregroundStyle(Color.labelStrong)
          
          Image(systemName: Layout.EmptyTeamspaceViewLayout.imageName)
            .font(.system(size: Layout.EmptyTeamspaceViewLayout.imageFontSize, weight: .medium))
            .foregroundStyle(Color.labelStrong)
        }
        .padding(.vertical, 6.5)
      }
    }
  }
  
  
  // MARK: - 팀 스페이스가 있을 때 보이는 뷰
  @ViewBuilder
  private var nonEmptyTeamspaceView: some View {
    if !(projectListViewModel.editingState.rowState == .editing) {
      HStack(spacing: 8) {
        Group {
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
        .padding(.vertical, 6.5)
      }
    }
  }
}


// MARK: - 프리뷰

#Preview("팀 없을 때") {
  ZStack {
    Color.backgroundNormal.ignoresSafeArea()
    TeamspaceTitleView(
      viewModel: HomeViewModel(),
      projectListViewModel: ProjectListViewModel()
    )
    .environmentObject(MainRouter())
  }
}

