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
            ToolbarLeadingBackButton()
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
                    // TODO: 팀 스페이스 글자 제한 고려
                    // TODO: 팀 스페이스 이름 미 입력 후 만들기 버튼 탭 시 보여질 뷰 고려
                    TextField("팀 이름을 입력해주세요", text: $teamspaceNameText)
                        .multilineTextAlignment(.center)
                }
        }
    }
    
    // MARK: - 바텀 팀 스페이스 만들기 뷰
    private var bottomButtonView: some View {
        // TODO: 컴포넌트 고려
        Button {
            Task {
                do {
                    try await viewModel.createTeamsapce(
                        userId: "4150C2CF-27DD-4B32-9313-0454258814BF1",
                        teamspaceName: teamspaceNameText
                    )
                    router.pop()
                } catch {
                    // FIXME: - 에러 분기 처리 추가하기
                    print("error: \(error.localizedDescription)")
                }
            }
        } label: {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.gray) // FIXME: - 컬러 수정
                .frame(maxWidth: .infinity)
                .frame(height: 47)
                .overlay {
                    Text("팀 스페이스 만들기")
                        .font(Font.system(size: 15, weight: .medium)) // FIXME: - 폰트 수정
                        .foregroundStyle(Color.black) // FIXME: - 컬러 수정
                }
        }
    }
    
}

#Preview {
    NavigationStack {
        CreateTeamspaceView()
    }
}
