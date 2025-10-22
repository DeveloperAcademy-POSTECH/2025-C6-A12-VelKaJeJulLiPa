//
//  CreateTracksView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/22/25.
//

import SwiftUI

struct CreateTracksView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: CreateTracksViewModel = .init()
    @State private var trackNameText = ""
    
    @FocusState private var isFocusTextField: Bool
    
    @Binding var choiceSelectedProject: Project?
    var onCreated: () -> Void = {}
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea() // FIXME: - 컬러 수정
            
            VStack {
                Spacer()
                inputTrackNameView
                    .padding(.horizontal, 16)
                Spacer()
                bottomButtonView
                    .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - 팀 스페이스 텍스트 필드 뷰 ("팀 스페이스 이름" + 텍스트 필드)
    private var inputTrackNameView: some View {
        VStack(spacing: 32) {
            Text("추가할 곡의 이름을 입력하세요")
                .font(Font.system(size: 24, weight: .medium)) // FIXME: - 폰트 수정
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
                        TextField("노래 이름", text: $trackNameText)
                            .font(Font.system(size: 16, weight: .medium)) // FIXME: - 폰트 수정
                            .foregroundStyle(Color.black) // FIXME: - 컬러 수정
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 16)
                            .overlay(alignment: .trailing) {
                                XmarkButton { self.trackNameText = "" }
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
            color: self.trackNameText.isEmpty ? Color.gray : Color.blue, // FIXME: - 컬러 수정
            height: 47,
            isEnabled: self.trackNameText.isEmpty ? false : true
        ) {
            Task {
                try await viewModel.createTracks(
                    projectId: choiceSelectedProject?.projectId.uuidString ?? "",
                    tracksName: trackNameText
                )
                onCreated()
                await MainActor.run { dismiss() }
            }
            dismiss()
        }
    }
}

#Preview {
    CreateTracksView(
        choiceSelectedProject: .constant(
            .init(
                projectId: UUID(),
                teamspaceId: "",
                creatorId: "",
                projectName: ""
            )
        )
    )
}
