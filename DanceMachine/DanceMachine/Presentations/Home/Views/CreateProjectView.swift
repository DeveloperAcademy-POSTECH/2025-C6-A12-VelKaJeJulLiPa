//
//  CreateProjectView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/17/25.
//

import SwiftUI

struct CreateProjectView: View {
    
    
    @EnvironmentObject private var router: NavigationRouter
    
    @State private var viewModel: CreateProjectViewModel = .init()
    @State private var projectNameText = ""
    
    @FocusState private var isFocusTextField: Bool
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea() // FIXME: - 컬러 수정
            
            VStack {
                Spacer()
                inputTeamspaceNameView
                    .padding(.horizontal, 16)
                Spacer()
                bottomButtonView
                    .padding(.horizontal, 16)
            }
        }
        .toolbar {
            ToolbarLeadingBackButton(icon: .chevron)
        }
    }
    
    // MARK: - 팀 스페이스 텍스트 필드 뷰 ("팀 스페이스 이름" + 텍스트 필드)
    private var inputTeamspaceNameView: some View {
        VStack(spacing: 32) {
            Text("프로젝트명을 입력하세요.")
                .font(Font.system(size: 24, weight: .semibold)) // FIXME: - 폰트 수정
                .foregroundStyle(Color.black) // FIXME: - 컬러 수정
            
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.gray) // FIXME: - 컬러 수정
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isFocusTextField ? Color.blue : Color.clear, lineWidth: isFocusTextField ? 1 : 0) // FIXME: - 컬러 수정
                )
                .frame(maxWidth: .infinity)
                .frame(height: 47)
                .overlay {
                    HStack {
                        // TODO: 컴포넌트 추가하기
                        TextField("프로젝트명", text: $projectNameText)
                            .font(Font.system(size: 16, weight: .medium)) // FIXME: - 폰트 수정
                            .foregroundStyle(Color.black) // FIXME: - 컬러 수정
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 16)
                            .overlay(alignment: .trailing) {
                                XmarkButton { self.projectNameText = "" }
                                .padding(.trailing, 8)
                            }
                    }
                }
                .focused($isFocusTextField)
        }
    }
    
    // MARK: - 바텀 팀 스페이스 만들기 뷰
    private var bottomButtonView: some View {
        ActionButton(
            title: "확인",
            color: self.projectNameText.isEmpty ? Color.gray : Color.blue, // FIXME: - 컬러 수정
            height: 47,
            isEnabled: self.projectNameText.isEmpty ? false : true
        ) {
            Task {
                try await viewModel.createProject(projectName: self.projectNameText)
                await MainActor.run { router.pop() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CreateProjectView()
    }
}

