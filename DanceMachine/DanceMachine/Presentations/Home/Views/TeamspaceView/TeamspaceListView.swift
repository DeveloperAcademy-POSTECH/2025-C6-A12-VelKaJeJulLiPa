//
//  TeamspaceListView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/8/25.
//

import SwiftUI

struct TeamspaceListView: View {
  
  @EnvironmentObject private var router: NavigationRouter
  
  @State private var viewModel: TeamspaceListViewModel = .init()
  
  @State private var userTeamspaces: [UserTeamspace] = []
  @State private var loadTeamspaces: [Teamspace] = []
  
  @State private var isLoading: Bool = false
  
  @State private var presentingCreateTeamspaceSheet: Bool = false
  
  // 프리뷰·테스트용 주입 이니셜라이저
  init(previewLoadTeamspaces: [Teamspace] = []) {
    _loadTeamspaces = State(initialValue: previewLoadTeamspaces)
  }
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea() // FIXME: - 컬러 수정
      List {
        ForEach(loadTeamspaces, id: \.teamspaceId) { teamspace in
          TeamspaceListItem(title: teamspace.teamspaceName)
            .simultaneousGesture(
              TapGesture().onEnded {
                viewModel.fetchCurrentTeamspace(teamspace: teamspace)
                router.pop()
              }
            )
            .listRowSeparator(.hidden)
            .listRowBackground(Color.backgroundNormal)
        }
        
        TeamspaceListItem(
          title: "팀 스페이스 만들기",
          isCreated: true
        )
        .simultaneousGesture(
          TapGesture().onEnded {
            self.presentingCreateTeamspaceSheet = true
          }
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.backgroundNormal)
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
    }
    .overlay { if isLoading { LoadingView() } }
    .toolbar {
      ToolbarLeadingBackButton(icon: .chevron)
      ToolbarCenterTitle(text: "팀 스페이스")
    }
    .sheet(isPresented: $presentingCreateTeamspaceSheet) {
      CreateTeamspaceView(onCreated: {
        Task {
          self.isLoading = true
          defer { isLoading = false }
          let newloaded = (try? await viewModel.loadTeamspacesForUser()) ?? []
          if newloaded != self.loadTeamspaces {
            let loaded: [Teamspace] = (try? await viewModel.loadTeamspacesForUser()) ?? []
            self.loadTeamspaces = loaded
          }
        }
      })
      .presentationDragIndicator(.visible)
      .presentationDetents([.fraction(0.9)])
      .presentationCornerRadius(16)
    }
    .task {
      if ProcessInfo.isRunningInPreviews { return } // 프리뷰 전용
      self.isLoading = true
      defer { isLoading = false }
      
      let loaded: [Teamspace] = (try? await viewModel.loadTeamspacesForUser()) ?? []
      self.loadTeamspaces = loaded
    }
  }
}

//#Preview {
//  NavigationStack {
//    TeamspaceListView(previewLoadTeamspaces: Teamspace.TeamspaceMockData)
//      .environmentObject(NavigationRouter())
//  }
//}

