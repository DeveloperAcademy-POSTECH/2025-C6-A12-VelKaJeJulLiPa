//
//  ContentView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject private var router: NavigationRouter
    
    @State private var viewModel: HomeViewModel = .init()
    @State private var userTeamspaces: [UserTeamspace] = []
    @State private var loadTeamspaces: [Teamspace] = []
    
    @State private var teamspaceState: TeamspaceRoute?
    
    @Binding var titleTeamspace: Teamspace? // FIXME: - 적절한지
    @State private var didInitializeTitle: Bool = false // 첫 설정 여부
    @State private var isLoading: Bool = false
    
    var body: some View {
        ZStack {
            Color.white // FIXME: - 컬러 수정
            
            VStack {
                topTitleView
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .overlay { if isLoading { LoadingView() } }
        .task {
            self.isLoading = true
            defer { isLoading = false }
            
            do {
                self.userTeamspaces = try await self.viewModel.fetchUserTeamspace(userId: MockData.userId) // FIXME: - Mock데이터 교체
                
                print("userTeamspace: \(self.userTeamspaces)")
                
                self.teamspaceState = userTeamspaces.isEmpty ? .create : .list
                self.loadTeamspaces = try await viewModel.fetchTeamspaces(userTeamspaces: userTeamspaces)
                
                if !didInitializeTitle {
                    defer { self.didInitializeTitle = true }
                    await MainActor.run {
                        self.titleTeamspace = loadTeamspaces.first
                    }
                }
            } catch {
                // FIXME: - 적절한 에러 분기 처리 진행하기
                print("error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 탑 타이틑 뷰 (팀 스페이스 + 설정 아이콘)
    private var topTitleView: some View {
        HStack {
            switch teamspaceState {
            case .none, .create:
                Button {
                    router.push(to: .teamspace(.create))
                } label: {
                    Text("팀 스페이스를 생성해주세요>")
                        .font(Font.title3) // FIXME: - 폰트 수정
                        .foregroundStyle(Color.black) // FIXME: - 컬러 수정
                }
            case .list, .setting:
                Button {
                    router.push(to: .teamspace(.list))
                } label: {
                    Text(self.titleTeamspace?.teamspaceName ?? "")
                        .font(Font.title3) // FIXME: - 폰트 수정
                        .foregroundStyle(Color.black) // FIXME: - 컬러 수정
                }
            }
            Spacer()
            switch teamspaceState {
            case .none, .create:
                EmptyView()
            case .list, .setting:
                Button {
                    router.push(to: .teamspace(.setting))
                } label: {
                    Image(systemName: "person.2.badge.gearshape.fill") // FIXME: - 이미지 수정
                        .foregroundStyle(Color.black) // FIXME: - 컬러 수정
                }
            }
        }
    }
    
    
}

#Preview {
    NavigationStack {
        HomeView(
            titleTeamspace: .constant(
                .init(
                    teamspaceId: UUID(),
                    ownerId: "aaaa",
                    teamspaceName: "벨카제줄리파"
                )
            )
        )
        .environmentObject(NavigationRouter())
    }
}
