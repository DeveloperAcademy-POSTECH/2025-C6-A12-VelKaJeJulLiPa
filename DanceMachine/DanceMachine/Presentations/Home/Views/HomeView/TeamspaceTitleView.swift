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
  
  @Binding var presentingCreateTeamspaceSheet: Bool
  
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
        self.presentingCreateTeamspaceSheet = true
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
    HStack(spacing: 8) {
      Button {
        print("router.push(to: .teamspace(.list))")
        router.push(to: .teamspace(.list))
      } label: {
        Text(viewModel.currentTeamspaceName)
          .font(.headline1Medium)
          .foregroundStyle(Color.labelStrong)
      }
      .clearGlassButtonIfAvailable()
      
      Button {
        router.push(to: .teamspace(.setting))
      } label: {
        Image(systemName: "person.2.badge.gearshape.fill")
          .foregroundStyle(Color.labelStrong)
//        Text("편집")
//          .font(.headline1Medium)
//          .foregroundStyle(Color.labelStrong)
      }
      .clearGlassButtonIfAvailable()
      
      Spacer()
    }
  }
}


// MARK: - 프리뷰

#Preview("팀 없을 때") {
  ZStack {
    Color.backgroundNormal.ignoresSafeArea()
    
    TeamspaceTitleView(
      viewModel: HomeViewModel(),
      teamspaceState: .constant(.empty),
      presentingCreateTeamspaceSheet: .constant(false)
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
        teamspaceState: $state,
        presentingCreateTeamspaceSheet: .constant(false)
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

