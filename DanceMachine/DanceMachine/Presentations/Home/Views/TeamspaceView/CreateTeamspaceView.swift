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
    VStack() {
      
      Text("팀 스페이스 이름")
        .font(Font.system(size: 20, weight: .semibold)) // FIXME: - 폰트 수정
        .foregroundStyle(Color.black) // FIXME: - 컬러 수정
      
      Spacer().frame(height: 32)
      
      RoundedRectangle(cornerRadius: 5)
        .fill(Color.gray) // FIXME: - 컬러 수정
        .frame(maxWidth: .infinity)
        .frame(height: 47)
        .overlay {
          TextField("팀 이름을 입력해주세요", text: $teamspaceNameText)
            .multilineTextAlignment(.center)
            .onChange(of: teamspaceNameText) { oldValue, newValue in
              var updated = newValue

              // Prevent leading space as the first character
              if updated.first == " " {
                updated = String(updated.drop(while: { $0 == " " })) // ❗️공백 금지
              }

              // Enforce 20-character limit
              if updated.count > 20 {
                updated = String(updated.prefix(20)) // ❗️20글자 초과 금지
              }

              if updated != teamspaceNameText {
                teamspaceNameText = updated
              }
            }
        }
        .overlay(
          RoundedRectangle(cornerRadius: 5)
            .stroke(teamspaceNameText.count > 19 ? Color.red : Color.clear, lineWidth: 2)
        )
      
      Spacer().frame(height: 16)
      
      Text("20자 이내로 입력해주세요.")
        .font(Font.system(size: 14, weight: .medium)) // FIXME: - 폰트 수정
        .foregroundStyle(Color.red) // FIXME: - 컬러 수정
        .opacity(teamspaceNameText.count < 20 ? 0 : 1)
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
