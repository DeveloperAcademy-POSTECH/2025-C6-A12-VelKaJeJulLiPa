//
//  TeamspaceNameUpdateView.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/18/25.
//

import SwiftUI

import SwiftUI

struct TeamspaceNameUpdateView: View {
  
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var router: MainRouter
  
  @Bindable var viewModel: TeamspaceSettingViewModel
  
  @State private var teamspaceNameText = ""
  
  @State private var closeAlert: Bool = false
  @State private var showMaxLengthWarning: Bool = false
  @FocusState private var isFocusTextField: Bool
  @State private var isUpdatingName: Bool = false
  
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
      
      // 시트 전체 로딩 오버레이 (원하면)
      if isUpdatingName {
        Color.black.opacity(0.25)
          .ignoresSafeArea()
        LoadingSpinner()
          .frame(width: 40, height: 40)
      }
    }
    .alert(
      "변경사항이 저장되지 않았습니다.\n종료하시겠어요?",
      isPresented: $closeAlert
    ) {
      Button("취소", role: .cancel) {}
      Button("종료", role: .destructive) { dismiss() }
    } message: {
      Text("저장하지 않은 변경사항은 사라집니다.")
    }
    .onAppear {
      // 현재 팀 스페이스 이름을 기본값으로 세팅
      self.teamspaceNameText = viewModel.currentTeamspace?.teamspaceName
      ?? viewModel.dataState.selectedTeamspaceName
    }
  }
  
  // MARK: - 탑 타이틀
  private var topTitleView: some View {
    ZStack {
      Text("팀 스페이스 이름 수정")
        .font(.headline2SemiBold)
        .foregroundStyle(Color.labelStrong)
        .frame(maxWidth: .infinity, alignment: .center)
      
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
  
  // MARK: - 이름 입력 필드
  private var inputTeamspaceNameView: some View {
    VStack {
      Text("팀 스페이스 이름을 입력하세요.")
        .font(.title2SemiBold)
        .foregroundStyle(Color.labelStrong)
      
      Spacer().frame(height: 32)
      
      TextField("팀 이름", text: $teamspaceNameText)
        .font(.headline2Medium)
        .foregroundStyle(Color.labelAssitive)
        .tint(Color.labelAssitive)
        .multilineTextAlignment(.center)
        .onChange(of: teamspaceNameText) { oldValue, newValue in
          var updated = newValue
          var overText = ""
          
          // 첫 글자 공백 제거
          if let first = updated.first, first == " " {
            updated = String(updated.drop(while: { $0 == " " }))
          }
          
          // 20자 제한 + 초과 감지
          if updated.count > 20 {
            let limited = String(updated.prefix(20))
            overText = String(updated.dropFirst(limited.count))
            updated = limited
          } else {
            overText = ""
          }
          
          showMaxLengthWarning = !overText.isEmpty
          
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
      
      Spacer().frame(height: 16)
      
      textFieldItem()
      
      Spacer().frame(height: 8)
      
      Text("20자 이내로 입력해주세요.")
        .font(.footnoteMedium)
        .foregroundStyle(Color.accentRedNormal)
        .opacity(showMaxLengthWarning ? 1 : 0)
    }
  }
  
  // MARK: - 바텀 버튼
  private var bottomButtonView: some View {
    ZStack {
      ActionButton(
        title: "확인",
        color: teamspaceNameText.isEmpty ? Color.fillAssitive : Color.secondaryStrong,
        height: 47,
        isEnabled: !teamspaceNameText.isEmpty && !isUpdatingName
      ) {
        Task {
          let trimmed = teamspaceNameText.trimmingCharacters(in: .whitespaces)
          guard !trimmed.isEmpty else { return }
          
          isUpdatingName = true
          defer { isUpdatingName = false }
          
          do {
            try await viewModel.renameCurrentTeamspaceAndReload(editedName: trimmed)
            await MainActor.run {
              dismiss()  // 시트 닫기
            }
          } catch {
            // TODO: 에러 토스트 / 알럿 등
            print("rename error: \(error.localizedDescription)")
          }
        }
      }
      .disabled(isUpdatingName)
      
      if isUpdatingName {
        RoundedRectangle(cornerRadius: 15)
          .fill(Color.fillAssitive)
          .frame(height: 47)
        LoadingSpinner()
          .frame(width: 28, height: 28)
      }
    }
    .padding(.bottom, 16)
  }
  
  // MARK: - 글자수 표시
  @ViewBuilder
  func textFieldItem() -> some View {
    Text("\(teamspaceNameText.count)/20")
      .font(.headline2Medium)
      .foregroundStyle(Color.secondaryNormal)
  }
}

#Preview {
  TeamspaceNameUpdateView(viewModel: TeamspaceSettingViewModel())
}
