//
//  AccountRecoveryView.swift
//  DanceMachine
//
//  Created by 조재훈 on 1/13/26.
//

import SwiftUI

struct AccountRecoveryView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel = AccountRecoveryViewModel()

  var body: some View {
    ZStack {
      Color.backgroundElevated.ignoresSafeArea()

      VStack(spacing: 0) {
        switch viewModel.currentStep {
        case .nameInput:
          nameInputStep
        case .teamspaceSelection:
          teamspaceSelectionStep
        case .result:
          resultStep
        }
      }
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button(action: {
          if !viewModel.isLoading {
            dismiss()
          }
        }) {
          Image(systemName: "chevron.left")
            .foregroundStyle(viewModel.isLoading ? Color.labelAssitive : Color.labelStrong)
        }
        .disabled(viewModel.isLoading)
      }
      ToolbarCenterTitle(text: String(localized: "계정 복구"))
    }
    .dismissKeyboardOnTap()
    .interactiveDismissDisabled(viewModel.isLoading)
    .onAppear {
      // 이메일이 Unknown이거나 이름이 비어있거나 Unknown인 계정만 복구 가능
      let currentEmail = FirebaseAuthManager.shared.userInfo?.email ?? "Unknown"
      let currentName = FirebaseAuthManager.shared.userInfo?.name ?? "Unknown"

      let isRecoverable = currentEmail == "Unknown" || currentName.isEmpty || currentName == "Unknown"

      if !isRecoverable {
        viewModel.errorMessage = String(localized: "계정 복구 대상이 아닙니다. 고객지원에 문의해 주세요.")
        viewModel.showError = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          dismiss()
        }
      }
    }
    .toast(
      isPresented: $viewModel.showError,
      duration: 2,
      position: .bottom,
      bottomPadding: 79,
      content: {
        ToastView(
          text: viewModel.errorMessage,
          icon: .warning
        )
      }
    )
    .toast(
      isPresented: $viewModel.showLoadingToast,
      duration: 30,
      position: .bottom,
      bottomPadding: 79,
      content: {
        ToastView(
          text: viewModel.loadingToastMessage,
          icon: .check
        )
      }
    )
  }

  // MARK: - Step 1: Name Input
  private var nameInputStep: some View {
    VStack(spacing: 0) {
      Text("복구할 계정의 사용자 이름을 입력해주세요")
        .font(.title2SemiBold)
        .foregroundStyle(Color.labelStrong)
        .padding(.top, 24)

      Spacer().frame(height: 16)

      Text("이전에 사용하던 계정의 사용자 이름을 정확히 입력해주세요.")
        .font(.headline1Medium)
        .foregroundStyle(Color.labelNormal)
        .multilineTextAlignment(.center)

      Spacer().frame(height: 32)

      TextField(String(localized: "이름"), text: $viewModel.userName)
        .font(.headline1Medium)
        .foregroundStyle(Color.labelStrong)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.backgroundNormal)
        .cornerRadius(8)
        .padding(.horizontal, 16)

      Spacer()
    }
    .safeAreaInset(edge: .bottom) {
        ActionButton(
          title: viewModel.isLoading ? String(localized: "계정 검색 중...") : String(localized: "다음"),
          color: viewModel.userName.isEmpty ? Color.fillAssitive : Color.secondaryStrong,
          height: 47,
          isEnabled: !viewModel.userName.isEmpty && !viewModel.isLoading,
          isLoading: viewModel.isLoading
        ) {
          Task {
            await viewModel.findAccount()
          }
        }
        .padding(.all, 16)
    }
  }

  // MARK: - Step 2: Teamspace Selection
  private var teamspaceSelectionStep: some View {
    VStack(spacing: 0) {
      Text("소속된 팀스페이스를 선택해주세요")
        .font(.title2SemiBold)
        .foregroundStyle(Color.labelStrong)
        .padding(.top, 24)

      Spacer().frame(height: 16)

      Text("보안을 위해 본인이 속해있던 팀스페이스를 선택해주세요.")
        .font(.headline1Medium)
        .foregroundStyle(Color.labelNormal)
        .multilineTextAlignment(.center)

      Spacer().frame(height: 8)

      Text("⚠️ 복구 작업은 1~2분 정도 소요될 수 있습니다.\n화면을 이탈하지 말고 기다려주세요.")
        .font(.caption1Medium)
        .foregroundStyle(Color.labelAssitive)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)

      Spacer().frame(height: 24)

      VStack(spacing: 12) {
        ForEach(viewModel.teamspaceOptions) { option in
          TeamspaceOptionButton(
            title: option.name,
            isSelected: viewModel.selectedTeamspaceId == option.id
          ) {
            viewModel.selectedTeamspaceId = option.id
          }
        }
      }
      .padding(.horizontal, 16)

      Spacer()
    }
    .safeAreaInset(edge: .bottom) {
        ActionButton(
          title: viewModel.isLoading ? String(localized: "계정 복구 중...") : String(localized: "계정 복구"),
          color: viewModel.selectedTeamspaceId == nil ? Color.fillAssitive : Color.secondaryStrong,
          height: 47,
          isEnabled: viewModel.selectedTeamspaceId != nil && !viewModel.isLoading,
          isLoading: viewModel.isLoading
        ) {
          Task {
            await viewModel.verifyAndRecover()
          }
        }
        .padding(.all, 16)
    }
  }

  // MARK: - Step 3: Result
  private var resultStep: some View {
    VStack(spacing: 0) {
      Spacer()
      if viewModel.recoverySuccess {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 64))
          .foregroundStyle(Color.green)

        Spacer().frame(height: 24)

        Text("계정 복구 성공!")
          .font(.title2SemiBold)
          .foregroundStyle(Color.labelStrong)

        Spacer().frame(height: 16)

        Text(viewModel.recoveryMessage)
          .font(.headline1Medium)
          .foregroundStyle(Color.labelNormal)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 32)

        Spacer().frame(height: 24)

        VStack(spacing: 8) {
          Text("복구되지 않은 데이터가 있다면")
            .font(.caption1Medium)
            .foregroundStyle(Color.labelAssitive)

          Text("마이페이지 > 문의 및 고객 지원에서 문의해 주세요.")
            .font(.caption1Medium)
            .foregroundStyle(Color.labelAssitive)

          Spacer().frame(height: 12)

          Text("더 나은 서비스를 위해 노력하겠습니다.")
            .font(.headline1Medium)
            .foregroundStyle(Color.labelNormal)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
      } else {
        Image(systemName: "xmark.circle.fill")
          .font(.system(size: 64))
          .foregroundStyle(Color.red)

        Spacer().frame(height: 24)

        Text("계정 복구 실패")
          .font(.title2SemiBold)
          .foregroundStyle(Color.labelStrong)

        Spacer().frame(height: 16)

        Text(viewModel.recoveryMessage)
          .font(.headline1Medium)
          .foregroundStyle(Color.labelNormal)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 32)
      }

      Spacer()
    }
    .safeAreaInset(edge: .bottom) {
      VStack(spacing: 12) {
        if viewModel.recoverySuccess {
          ActionButton(
            title: String(localized: "확인"),
            color: Color.secondaryStrong,
            height: 47
          ) {
            dismiss()
          }
        } else {
          ActionButton(
            title: String(localized: "다시 시도"),
            color: Color.secondaryStrong,
            height: 47
          ) {
            viewModel.reset()
          }

          ActionButton(
            title: String(localized: "취소"),
            color: Color.fillAssitive,
            height: 47
          ) {
            dismiss()
          }
        }
      }
      .padding(.all, 16)
    }
  }
}

// MARK: - Teamspace Option Button
fileprivate struct TeamspaceOptionButton: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        Text(title)
          .font(.body1Medium)
          .foregroundStyle(isSelected ? Color.white : Color.labelStrong)

        Spacer()

        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(Color.white)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 16)
      .background(isSelected ? Color.secondaryStrong : Color.backgroundNormal)
      .cornerRadius(8)
    }
  }
}

#Preview {
  NavigationStack {
    AccountRecoveryView()
  }
}
