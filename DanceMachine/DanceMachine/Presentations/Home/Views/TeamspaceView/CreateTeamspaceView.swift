//
//  CreateTeamspaceView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/8/25.
//

import SwiftUI

struct CreateTeamspaceView: View {
    
    @EnvironmentObject private var router: NavigationRouter
    
    @State private var viewModel: CreateTeamspaceViewModel = .init()
    @State private var teamspaceNameText = ""
    
    var body: some View {
        ZStack {
            Color.white // FIXME: - 컬러 수정
            
            VStack {
                Spacer()
                inputTeamspaceNameView
                Spacer()
                bottomButtonView
            }
        }
        .padding(.horizontal, 16)
        .toolbar {
          ToolbarLeadingBackButton(icon: .chevron)
        }
    }
    
    // MARK: - 팀 스페이스 텍스트 필드 뷰 ("팀 스페이스 이름" + 텍스트 필드)
    private var inputTeamspaceNameView: some View {
        VStack(spacing: 10) {
            Text("팀 스페이스 이름")
                .font(Font.system(size: 20, weight: .semibold)) // FIXME: - 폰트 수정
                .foregroundStyle(Color.black) // FIXME: - 컬러 수정
            
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.gray) // FIXME: - 컬러 수정
                .frame(maxWidth: .infinity)
                .frame(height: 47)
                .overlay {
                    TextField("팀 이름을 입력해주세요", text: $teamspaceNameText)
                        .multilineTextAlignment(.center)
                }
        }
    }
    
    // MARK: - 바텀 팀 스페이스 만들기 뷰
    private var bottomButtonView: some View {
        ActionButton(
            title: "확인",
            color: self.teamspaceNameText.isEmpty ? Color.gray : Color.blue, // FIXME: - 컬러 수정
            height: 47,
            isEnabled: self.teamspaceNameText.isEmpty ? false : true
        ) {
            Task {
                try await self.viewModel.createTeamspaceWithInitialMembership(
                    teamspaceNameText: teamspaceNameText
                )
                await MainActor.run { router.pop() }
            }
            
        }
    }
}

#Preview {
    NavigationStack {
        CreateTeamspaceView()
    }
}
