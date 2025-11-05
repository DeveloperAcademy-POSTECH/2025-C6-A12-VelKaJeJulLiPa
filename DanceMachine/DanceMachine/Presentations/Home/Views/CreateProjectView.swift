//
//  CreateProjectView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/17/25.
//

import SwiftUI

struct CreateProjectView: View {
  
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var router: NavigationRouter
  
  @State private var viewModel: CreateProjectViewModel = .init()
  @State private var projectNameText = ""
  
  @FocusState private var isFocusTextField: Bool
  
  var body: some View {
    ZStack {
      Color.backgroundElevated.ignoresSafeArea()
      
      VStack {
        Spacer().frame(height: 29)
        topTitleView
        Spacer()
        inputProjectNameView
          .padding(.horizontal, 16)
        Spacer()
        bottomButtonView
          .padding(.horizontal, 16)
      }
    }
  }
  
  
  // MARK: - 탑 타이틀
  private var topTitleView: some View {
    HStack {
      // TODO: Xmark 버튼 추가, alert 처리.
      //Image(systemName: "xmark.circle.fill")
      // TODO: 홈 시트 작업 중이였음. (컬러가 아직 피그마 반영이 안돼서, 잠시 빼둠.)
      Text("새 프로젝트 만들기")
        .font(.headline2SemiBold)
        .foregroundStyle(Color.labelStrong)
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
            // TODO: 컴포넌트 추가하기
            TextField("프로젝트 이름", text: $projectNameText)
              .font(.headline2Medium)
              .foregroundStyle(Color.labelStrong)
              .multilineTextAlignment(.center)
              .padding(.vertical, 15)
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
      title: "프로젝트 생성하기",
      color: self.projectNameText.isEmpty ? Color.fillAssitive : Color.secondaryStrong,
      height: 47,
      isEnabled: self.projectNameText.isEmpty ? false : true
    ) {
      Task {
        try await viewModel.createProject(projectName: self.projectNameText)
        await MainActor.run { dismiss() }
      }
    }
    .padding(.bottom, 16)
  }
}

#Preview {
  NavigationStack {
    CreateProjectView()
  }
}

