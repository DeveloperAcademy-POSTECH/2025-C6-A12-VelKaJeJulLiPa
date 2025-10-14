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
    
    var body: some View {
        ZStack {
            Color.white // FIXME: - 컬러 수정
            
            VStack {
                Spacer()
                List(loadTeamspaces, id: \.teamspaceId) { teamspace in
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray) // FIXME: - 컬러 수정
                        .frame(maxWidth: .infinity)
                        .frame(height: 43)
                        .overlay {
                            Text(teamspace.teamspaceName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.black)
                        }
                        .onTapGesture {
                            viewModel.fetchCurrentTeamspace(teamspace: teamspace)
                            router.pop()
                        }
                }
                Spacer()
                bottomButtonView
            }
        }
        .padding(.horizontal, 16)
        .overlay { if isLoading { LoadingView() } }
        .toolbar {
            ToolbarLeadingBackButton()
            ToolbarCenterTitle(text: "팀 스페이스")
        }
        .task {
            self.isLoading = true
            defer { isLoading = false }
            
            do {
                self.userTeamspaces = try await self.viewModel.fetchUserTeamspace(userId: MockData.userId) // FIXME: - Mock데이터 교체
                self.loadTeamspaces = try await viewModel.fetchTeamspaces(userTeamspaces: userTeamspaces)
                print("loadTeamspaces: \(loadTeamspaces)")
            } catch {
                print("error: \(error.localizedDescription)") // FIXME: - 적절한 에러 분기 처리
            }
        }
    }
    
    // MARK: - 바텀 팀 스페이스 만들기 뷰
    private var bottomButtonView: some View {
        // TODO: 컴포넌트 고려
        Button {
            router.push(to: .teamspace(.create))
        }
        label: {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.gray) // FIXME: - 컬러 수정
                .frame(maxWidth: .infinity)
                .frame(height: 47)
                .overlay {
                    Text("팀 스페이스 추가하기")
                        .font(Font.system(size: 15, weight: .medium)) // FIXME: - 폰트 수정
                        .foregroundStyle(Color.black) // FIXME: - 컬러 수정
                }
        }
    }
}

#Preview {
    NavigationStack {
        TeamspaceListView()
            .environmentObject(NavigationRouter())
    }
}
