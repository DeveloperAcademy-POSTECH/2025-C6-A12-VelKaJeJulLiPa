//
//  CreateTeamspaceView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/8/25.
//

import SwiftUI

struct CreateTeamspaceView: View {
  
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var router: MainRouter
  
  @State private var viewModel: CreateTeamspaceViewModel = .init()
  @State private var teamspaceNameText = ""
  
  @State private var closeAlert: Bool = false
  
  @FocusState private var isFocusTextField: Bool
  
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
        inputTeamspaceNameView
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
      Text("팀 스페이스 만들기")
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
  
  // MARK: - 팀 스페이스 텍스트 필드 뷰 ("팀 스페이스 이름" + 텍스트 필드)
  private var inputTeamspaceNameView: some View {
    VStack {
      Text("팀 스페이스 이름을 입력하세요.")
        .font(.title2SemiBold)
        .foregroundStyle(Color.labelStrong)
      
      Spacer().frame(height: 32)
      
      // 가운데 정렬 텍스트 필드 + 배경
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
        .frame(maxWidth: .infinity)
        .frame(height: 51)
        .background(
          RoundedRectangle(cornerRadius: 15)
            .fill(Color.fillStrong)
            .overlay(
              RoundedRectangle(cornerRadius: 15)
                .stroke(
                  isFocusTextField ? Color.secondaryStrong : Color.clear,
                  lineWidth: isFocusTextField ? 1 : 0
                )
            )
        )
        .overlay(alignment: .trailing) { textFieldItem() }
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
  
  // MARK: - 텍스트 필드 아이템 (글자수 라벨, x 버튼)
  @ViewBuilder
  func textFieldItem() -> some View {
    HStack(spacing: 9) {
      Text("\(teamspaceNameText.count)/20")
        .font(.headline2Medium)
        .foregroundStyle(Color.secondaryNormal)
      
      XmarkButton { self.teamspaceNameText = "" }
        .padding(.trailing, 8)
    }
  }
  
}

#Preview {
  NavigationStack {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      CreateTeamspaceView()
        .environmentObject(MainRouter())
    }
  }
}
