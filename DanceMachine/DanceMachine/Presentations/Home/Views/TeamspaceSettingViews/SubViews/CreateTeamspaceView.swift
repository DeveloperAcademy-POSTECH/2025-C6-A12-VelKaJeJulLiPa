//
//  CreateTeamspaceView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/8/25.
//

import SwiftUI

// TODO: 여기 조금 더 해야함.
struct CreateTeamspaceView: View {
  
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var router: MainRouter
  
  @State private var viewModel: CreateTeamspaceViewModel = .init()
  @State private var teamspaceNameText = ""
  
  @State private var closeAlert: Bool = false
  
  @State private var showMaxLengthWarning: Bool = false
  
  @FocusState private var isFocusTextField: Bool
  @State private var isCreatingTeamspace: Bool = false
  
  var onCreated: () -> Void = {} // FIXME: - 여부 확인
  
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
          var updated = newValue
          var overText = ""
          // 1) 첫 글자 공백 막기
          if let first = updated.first, first == " " {
            updated = String(updated.drop(while: { $0 == " " }))
          }
          // 2) 20자 초과 여부 체크
          if updated.count > 20 {
            // 앞 20자
            let limited = String(updated.prefix(20))
            // 20자 이후 초과분
            overText = String(updated.dropFirst(limited.count))
            // 실제 텍스트는 20자까지만 유지
            updated = limited
          } else {
            overText = ""
          }
          // 3) 초과 텍스트가 있으면 경고 ON
          self.showMaxLengthWarning = !overText.isEmpty
          // 4) 값이 달라졌을 때만 반영
          if updated != teamspaceNameText {
            teamspaceNameText = updated
          }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 51)
        .overlay(alignment: .trailing) {
          XmarkButton {
            self.teamspaceNameText = ""
            self.showMaxLengthWarning = false
          }
            .padding(.trailing, 8)
        }
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
        .focused($isFocusTextField)

//        .overlay(
//          RoundedRectangle(cornerRadius: 15)
//            .stroke(teamspaceNameText.count > 19 ? Color.accentRedNormal : Color.clear, lineWidth: 1)
//        )
      
      Spacer().frame(height: 16)
      
      textFieldItem()
      
//      Spacer().frame(height: 16)
     // TODO: 이거 채워넣기
//      Text("20자 이내로 입력해주세요.")
//        .font(.footnoteMedium)
//        .foregroundStyle(Color.accentRedNormal)
//        .opacity(showMaxLengthWarning ? 1 : 0)
      
    }
  }
  
  // MARK: - 바텀 팀 스페이스 만들기 뷰
  private var bottomButtonView: some View {
    ZStack {
      ActionButton(
        title: "팀 스페이스 만들기",
        color: teamspaceNameText.isEmpty ? Color.fillAssitive : Color.secondaryStrong,
        height: 47,
        isEnabled: !teamspaceNameText.isEmpty && !isCreatingTeamspace
      ) {
        Task {
          guard !teamspaceNameText.isEmpty else { return }
          isCreatingTeamspace = true
          defer { isCreatingTeamspace = false }
          
          try await viewModel.createTeamspaceWithInitialMembership(
            teamspaceNameText: teamspaceNameText
          )
          onCreated()
          await MainActor.run { dismiss() }
        }
      }
      .disabled(isCreatingTeamspace)
      
      // 로딩 오버레이
      if isCreatingTeamspace {
        // 버튼 영역을 꽉 채우는 배경
        RoundedRectangle(cornerRadius: 15)
          .fill(Color.fillAssitive)
          .frame(height: 47)
        
        LoadingSpinner()
          .frame(width: 28, height: 28)
      }
    }
    .padding(.bottom, 16)
  }
  
  // MARK: - 텍스트 필드 아이템 (글자수 라벨, x 버튼)
  @ViewBuilder
  func textFieldItem() -> some View {
    Text("\(teamspaceNameText.count)/20")
      .font(.headline2Medium)
      .foregroundStyle(Color.secondaryNormal)
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
