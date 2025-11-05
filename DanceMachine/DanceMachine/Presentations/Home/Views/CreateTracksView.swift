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
      Color.backgroundElevated.ignoresSafeArea()
      
      VStack {
        Spacer().frame(height: 29)
        topTitleCloseView
        Spacer()
        middleInputTrackNameView
          .padding(.horizontal, 16)
        Spacer()
        bottomButtonView
          .padding(.horizontal, 16)
      }
    }
  }
  
  // MARK: - 탑 타이틀, 닫기 버튼 뷰
  private var topTitleCloseView: some View {
    HStack {
      Text("곡 추가하기")
        .font(.headline2SemiBold)
        .foregroundStyle(Color.labelStrong)
    }
  }
  
  // MARK: - 미들 팀 스페이스 텍스트 필드 뷰 ("팀 스페이스 이름" + 텍스트 필드)
  private var middleInputTrackNameView: some View {
    VStack {
      Text("추가할 곡의 이름을 입력하세요")
        .font(.title2SemiBold)
        .foregroundStyle(Color.labelStrong)
      
      Spacer().frame(height: 32)
      
      RoundedRectangle(cornerRadius: 15)
        .fill(Color.fillStrong)
        .overlay(
          RoundedRectangle(cornerRadius: 15)
            .stroke(
              isFocusTextField ? Color.secondaryStrong : Color.clear,
              lineWidth: isFocusTextField ? 1 : 0
            )
        )
        .frame(maxWidth: .infinity)
        .frame(height: 51)
        .overlay {
          HStack {
            TextField("예) “세븐틴-만세", text: $trackNameText)
              .font(.headline2Medium)
              .foregroundStyle(Color.labelAssitive)
              .multilineTextAlignment(.center)
              .padding(.vertical, 16)
              .overlay(alignment: .trailing) {
                XmarkButton { self.trackNameText = "" }
                  .padding(.trailing, 8)
              }
          }
        }
        .onChange(of: trackNameText) { oldValue, newValue in
          var updated = newValue
          
          if updated.first == " " {
            updated = String(updated.drop(while: { $0 == " " })) // ❗️공백 금지
          }
          
          if updated.count > 20 {
            updated = String(updated.prefix(20)) // ❗️20글자 초과 금지
          }
          
          if updated != trackNameText {
            trackNameText = updated
          }
        }
        .overlay(
          RoundedRectangle(cornerRadius: 15)
            .stroke(trackNameText.count > 19 ? Color.accentRedNormal : Color.clear, lineWidth: 1)
        )
        .focused($isFocusTextField)
      
      Spacer().frame(height: 16)
      
      Text("20자 이내로 입력해주세요.")
        .font(.footnoteMedium)
        .foregroundStyle(Color.accentRedNormal)
        .opacity(trackNameText.count < 20 ? 0 : 1)
    }
  }
  
  // MARK: - 바텀 팀 스페이스 만들기 뷰
  private var bottomButtonView: some View {
    ActionButton(
      title: "곡 추가하기",
      color: self.trackNameText.isEmpty ? Color.fillAssitive : Color.secondaryStrong,
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
    }
    .padding(.bottom, 16)
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
