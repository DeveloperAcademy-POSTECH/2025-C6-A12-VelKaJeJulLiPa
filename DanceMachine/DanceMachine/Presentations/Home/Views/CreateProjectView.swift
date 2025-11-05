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
    VStack {
      Text("프로젝트명을 입력하세요.")
        .font(Font.system(size: 24, weight: .semibold)) // FIXME: - 폰트 수정
        .foregroundStyle(Color.black) // FIXME: - 컬러 수정
      
      Spacer().frame(height: 32)
      
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
          RoundedRectangle(cornerRadius: 5)
            .stroke(projectNameText.count > 19 ? Color.red : Color.clear, lineWidth: 2)
        )
        .focused($isFocusTextField)
      
      Spacer().frame(height: 16)
      
      Text("20자 이내로 입력해주세요.")
        .font(Font.system(size: 14, weight: .medium)) // FIXME: - 폰트 수정
        .foregroundStyle(Color.red) // FIXME: - 컬러 수정
        .opacity(projectNameText.count < 20 ? 0 : 1)
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
        //                await MainActor.run { router.pop() }
        await MainActor.run {
          dismiss()
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    CreateProjectView()
  }
}

