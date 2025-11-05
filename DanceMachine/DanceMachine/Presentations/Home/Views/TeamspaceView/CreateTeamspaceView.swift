//
//  CreateTeamspaceView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/8/25.
//

import SwiftUI

struct CreateTeamspaceView: View {
  
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var router: NavigationRouter
  
  @State private var viewModel: CreateTeamspaceViewModel = .init()
  @State private var teamspaceNameText = ""
  
  @FocusState private var isFocusTextField: Bool
  
  var onCreated: () -> Void = {}
  
  var body: some View {
    ZStack {
      Color.backgroundElevated.ignoresSafeArea()
      VStack {
        Spacer().frame(height: 29)
        topTitleView
        Spacer()
        inputTeamspaceNameView
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
      Text("팀 스페이스 만들기")
        .font(.headline2SemiBold)
        .foregroundStyle(Color.labelStrong)
    }
  }
  
  // MARK: - 팀 스페이스 텍스트 필드 뷰 ("팀 스페이스 이름" + 텍스트 필드)
  private var inputTeamspaceNameView: some View {
    VStack {
      Text("팀 스페이스 이름을 입력하세요.")
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
            Spacer()
            TextField("팀 이름", text: $teamspaceNameText)
              .font(.headline2Medium)
              .foregroundStyle(Color.labelAssitive)
              .tint(Color.labelAssitive)
              .multilineTextAlignment(.center)
              .onChange(of: teamspaceNameText) { oldValue, newValue in
                if newValue.count > 20 {
                  teamspaceNameText = String(newValue.prefix(20))
                }
              }
            
            Spacer()
            
            XmarkButton {
              self.teamspaceNameText = ""
            }
            .padding(.trailing, 8)
            
          }
        }
        .overlay(
          RoundedRectangle(cornerRadius: 15)
            .stroke(teamspaceNameText.count > 19 ? Color.accentRedNormal : Color.clear, lineWidth: 1)
        )
        .focused($isFocusTextField)
      
      Spacer().frame(height: 16)
      
      Text("20자 이내로 입력해주세요.")
        .font(.footnoteMedium)
        .foregroundStyle(Color.accentRedNormal)
        .opacity(teamspaceNameText.count < 20 ? 0 : 1)
    }
  }
  
  // MARK: - 바텀 팀 스페이스 만들기 뷰
  private var bottomButtonView: some View {
    ActionButton(
      title: "팀 스페이스 만들기",
      color: self.teamspaceNameText.isEmpty ? Color.fillAssitive : Color.secondaryStrong,
      height: 47,
      isEnabled: self.teamspaceNameText.isEmpty ? false : true
    ) {
      Task {
        try await self.viewModel.createTeamspaceWithInitialMembership(
          teamspaceNameText: teamspaceNameText
        )
        self.onCreated()
        await MainActor.run { dismiss() }
      }
    }
    .padding(.bottom, 16)
  }
  
}

#Preview {
  NavigationStack {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      CreateTeamspaceView()
        .environmentObject(NavigationRouter())
    }
  }
}
