//
//  CreateProjectView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/17/25.
//

import SwiftUI

struct CreateProjectView: View {
  
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var router: MainRouter
  
  @State private var viewModel: CreateProjectViewModel = .init()
  @State private var projectNameText = ""
  
  @FocusState private var isFocusTextField: Bool
  
  @State private var closeAlert: Bool = false
  
  var onCreated: () -> Void = {}
  
  var body: some View {
    ZStack {
      Color.backgroundElevated.ignoresSafeArea()
      
      VStack {
        Spacer().frame(height: 29)
        topTitleView
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 16)
        Spacer()
        inputProjectNameView
          .padding(.horizontal, 16)
        Spacer()
        bottomButtonView
          .padding(.horizontal, 16)
      }
      .dismissKeyboardOnTap()
    }
    .alert(
      "변경사항이 저장되지 않았습니다.\n종료하시겠어요?",
      isPresented: $closeAlert
    ) {
      Button("취소", role: .cancel) {}
      Button("나가기", role: .destructive) { dismiss() }
    } message: {
      Text("저장하지 않은 변경사항은 사라집니다.")
    }
  }
  
  
  // MARK: - 탑 타이틀
  private var topTitleView: some View {
    ZStack { // TODO: 서치
      // 가운데 정렬 타이틀
      Text("새 프로젝트 만들기")
        .font(.headline2SemiBold)
        .foregroundStyle(Color.labelStrong)
        .frame(maxWidth: .infinity, alignment: .center)
      
      // 왼쪽 X 버튼
      HStack {
        Image(systemName: "xmark.circle.fill")
          .resizable()
          .scaledToFit()
          .frame(width: 44, height: 44)
          .foregroundStyle(Color.labelNormal)
          .onTapGesture { self.closeAlert = true }
        Spacer()
      }
    }
  }
  
  // MARK: - 팀 스페이스 텍스트 필드 뷰 ("프로젝트 이름" + 텍스트 필드)
  private var inputProjectNameView: some View {
    VStack {
      Text("프로젝트 이름을 입력하세요.")
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
            TextField("예시: 학교 축제", text: $projectNameText)
              .font(.headline2Medium)
              .foregroundStyle(Color.labelStrong)
              .multilineTextAlignment(.center)
              .padding(.vertical, 15)
              .overlay(alignment: .trailing) { textFieldItem() }
              .overlay(alignment: .trailing) {
                XmarkButton { self.projectNameText = "" }
                  .padding(.trailing, 8)
              }
              .onChange(of: projectNameText) { oldValue, newValue in
                var updated = newValue
                
                if updated.first == " " {
                  updated = String(updated.drop(while: { $0 == " " })) // ❗️공백 금지
                }
                
                if updated.count > 20 {
                  updated = String(updated.prefix(20)) // ❗️20글자 초과 금지
                }
                
                if updated != projectNameText {
                  projectNameText = updated
                }
              }
          }
        }
        .overlay(
          RoundedRectangle(cornerRadius: 15)
            .stroke(
              projectNameText.count > 19 ? Color.accentRedNormal : Color.clear,
              lineWidth: 1
            )
        )
        .focused($isFocusTextField)
      
      Spacer().frame(height: 16)
      
      Text("20자 이내로 입력해주세요.")
        .font(.footnoteMedium)
        .foregroundStyle(Color.accentRedNormal)
        .opacity(projectNameText.count < 20 ? 0 : 1)
    }
  }
  
  // MARK: - 바텀 팀 스페이스 만들기 뷰
  private var bottomButtonView: some View {
    ActionButton(
      title: "새 프로젝트 만들기",
      color: self.projectNameText.isEmpty ? Color.fillAssitive : Color.secondaryStrong,
      height: 47,
      isEnabled: self.projectNameText.isEmpty ? false : true
    ) {
      Task {
        try await viewModel.createProject(projectName: self.projectNameText)
        self.onCreated()
        await MainActor.run { dismiss() }
      }
    }
    .padding(.bottom, 16)
  }
  
  // MARK: - 텍스트 필드 아이템 (글자수 라벨, x 버튼)
  @ViewBuilder
  func textFieldItem() -> some View {
    HStack(spacing: 9) {
      Text("\(projectNameText.count)/20")
        .font(.headline2Medium)
        .foregroundStyle(Color.secondaryNormal)
      
      XmarkButton { self.projectNameText = "" }
        .padding(.trailing, 8)
    }
  }
  
}

#Preview {
  NavigationStack {
    CreateProjectView()
  }
}

