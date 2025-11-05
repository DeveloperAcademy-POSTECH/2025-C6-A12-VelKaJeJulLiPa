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
            
            Spacer()
            
            XmarkButton {
              self.teamspaceNameText = ""
            }
            .padding(.trailing, 8)
            
          }
        }
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
        await MainActor.run { router.pop() }
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
