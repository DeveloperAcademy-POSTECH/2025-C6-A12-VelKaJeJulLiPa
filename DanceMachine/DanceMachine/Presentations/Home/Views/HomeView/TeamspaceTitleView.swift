//
//  TeamspaceTitleView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/28/25.
//

import SwiftUI

struct TeamspaceTitleView: View {
  
  @EnvironmentObject private var router: NavigationRouter
  @Bindable var viewModel: HomeViewModel
  
  @Binding var teamspaceState: TeamspaceState
  
  var body: some View {
    Group {
      switch teamspaceState {
      case .empty:
        emptyTeamspaceView
      case .nonEmpty:
        nonEmptyTeamspaceView
      }
    }
  }
  
  private var emptyTeamspaceView: some View {
    HStack {
      Button {
        print("router.push(to: .teamspace(.create))")
        router.push(to: .teamspace(.create))
      } label: {
        HStack {
          HStack(spacing: 8) {
            Text("팀 스페이스를 생성해주세요")
              .font(.heading1Medium)
              .foregroundStyle(Color.labelStrong)
            
            Image(systemName: "chevron.right")
              .font(.heading1Medium)
              .foregroundStyle(Color.labelStrong)
          }
        }
      }
      Spacer()
    }
  }
  
  private var nonEmptyTeamspaceView: some View {
    HStack {
      Button {
        print("router.push(to: .teamspace(.list))")
        router.push(to: .teamspace(.list))
      } label: {
        Text(viewModel.currentTeamspaceName)
          .font(.headline1Medium)
          .foregroundStyle(Color.labelStrong)
      }
      .clearGlassButtonIfAvailable()
      
      Spacer()
      
      Button {
        router.push(to: .teamspace(.setting))
      } label: {
        Text("편집")
          .font(.headline1Medium)
          .foregroundStyle(Color.labelStrong)
      }
      .clearGlassButtonIfAvailable()
    }
  }
}


// MARK: - 프리뷰

#Preview("팀 없을 때") {
  ZStack {
    Color.backgroundNormal.ignoresSafeArea()
    
    TeamspaceTitleView(
      viewModel: HomeViewModel(),
      teamspaceState: .constant(.empty)
    )
    .environmentObject(NavigationRouter())
  }
}

#Preview("팀 있을 때 (Mock)") {
  PreviewTeamspaceTitleNonEmpty()
}


private struct PreviewTeamspaceTitleNonEmpty: View {
  @State private var vm = HomeViewModel()
  @State private var state: TeamspaceState = .nonEmpty
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      
      TeamspaceTitleView(
        viewModel: vm,
        teamspaceState: $state
      )
      .environmentObject(NavigationRouter())
      .task {
        let mock = Teamspace(
          teamspaceId: UUID(),
          ownerId: "",
          teamspaceName: "댄스머신 팀"
        )
        
        FirebaseAuthManager.shared.currentTeamspace = mock
        
        vm.teamspace.list = [mock]
        vm.teamspace.state = .nonEmpty
        vm.teamspace.isLoading = false
      }
    }
  }
}

