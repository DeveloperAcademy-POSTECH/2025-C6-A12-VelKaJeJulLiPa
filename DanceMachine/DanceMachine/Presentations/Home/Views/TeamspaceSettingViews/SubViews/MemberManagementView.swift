//
//  MemberManagementView.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/18/25.
//

import SwiftUI

struct MemberManagementView: View {
  
  @Environment(\.dismiss) private var dismiss
  @Bindable var viewModel: TeamspaceSettingViewModel
  
  let user: User
  
  @State private var isUpdatingOwner: Bool = false  // 팀장 권한 변경 중
  @State private var isUpdateCompleted: Bool = false // 팀장 권한 변경 완료(버튼 비활성화 등 로직용)
  @State private var checkEffectActive: Bool = false //애니메이션 트리거 + 표시 조건
  @State private var isCloseTapped: Bool = false // X 버튼 bounce 애니메이션 트리거
  @State private var strokeColorTap = false
  
  var body: some View {
    ZStack {
      Color.backgroundElevated.ignoresSafeArea()
      
      VStack {
        Spacer().frame(height: 29)
        
        topTitleView
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 16)
        
        Spacer().frame(height: 32)
        
        contentView
          .padding(.horizontal, 16)
        
        Spacer()
      }
    }
  }
  
  // MARK: - Top Title
  
  private var topTitleView: some View {
    ZStack {
      Text("팀원 관리")
        .font(.headline2SemiBold)
        .foregroundStyle(Color.labelStrong)
        .frame(maxWidth: .infinity, alignment: .center)
      
      HStack {
        Image(systemName: "xmark.circle.fill")
          .resizable()
          .scaledToFit()
          .frame(width: 44, height: 44)
          .foregroundStyle(Color.labelNormal)
          .symbolEffect(.bounce, value: isCloseTapped)
          .onTapGesture {
            Task {
              await MainActor.run {
                isCloseTapped = true
              }
              try? await Task.sleep(for: .seconds(2.5))
              await MainActor.run {
                dismiss()
              }
            }
          }
        Spacer()
      }
    }
  }
  
  // MARK: - Content
  
  private var contentView: some View {
    VStack(spacing: 24) {
      
      // 유저 정보
      HStack(spacing: 12) {
        Circle()
          .fill(Color.fillSubtle)
          .frame(width: 40, height: 40)
          .overlay {
            Text(String(user.name.first ?? " "))
              .font(.headline2SemiBold)
              .foregroundStyle(Color.labelStrong)
          }
        Text(user.name)
          .font(.headline2SemiBold)
          .foregroundStyle(Color.labelStrong)
        Spacer()
      }
      
      // 팀장 권한 주기 버튼
      Button {
        giveOwnerRole()
        self.strokeColorTap = true
      } label: {
        HStack {
          Text("팀장 권한주기")
            .font(.headline2Medium)
            .foregroundStyle(Color.labelStrong)
          
          Spacer()
          
          ZStack {
            // 로딩 스피너
            if isUpdatingOwner {
              LoadingSpinner()
                .frame(width: 20, height: 20)
                .tint(Color.secondaryStrong)
            }
            
            // 체크 아이콘 (처음에는 안 보이고, checkEffectActive == true일 때만 보이게)
            if #available(iOS 26.0, *) {
              Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.secondaryStrong)
                .opacity(checkEffectActive ? 1 : 0)
                .symbolEffect(
                  .drawOn,
                  options: .nonRepeating,
                  isActive: !checkEffectActive
                )
            } else {
              // FIXME: - iOS 18 수정 진행하기
              Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.secondaryStrong)
                .opacity(checkEffectActive ? 1 : 0)
            }
          }
          .frame(width: 20, height: 20)
        }
        .padding(.horizontal, 16)
        .frame(height: 42)
        .frame(maxWidth: .infinity)
        .background(
          RoundedRectangle(cornerRadius: 15)
            .fill(Color.fillSubtle)
        )
        .background(
          RoundedRectangle(cornerRadius: 15)
            .stroke(strokeColorTap ? Color.secondaryStrong : Color.strokeStrong)
        )
      }
      .disabled(isUpdatingOwner || isUpdateCompleted)
      
      Spacer().frame(height: 55)
      
      Button {
        viewModel.teamspaceSettingPresentationState.selectedUserForRemoval = user
        viewModel.teamspaceSettingPresentationState.isPresentingChoiceMemberRemovalAlert = true
        dismiss()
      } label: {
        Text("팀에서 내보내기")
          .font(.headline2Medium)
          .foregroundStyle(Color.accentRedNormal)
          .frame(maxWidth: .infinity, alignment: .center)
      }
    }
  }
  
  // MARK: - Actions
  
  private func giveOwnerRole() {
    Task {
      await MainActor.run {
        isUpdateCompleted = false
        isUpdatingOwner = true
        checkEffectActive = false
      }
      
      do {
        // 실제 팀장 변경 로직
        try await viewModel.updateTeamspaceOwner(userId: user.userId) // TODO: 테스트 필요
       
        // 1) 로딩 종료 + 완료 상태로 전환, 그 순간 딱 한 번 보이면서 그리기 시작
        await MainActor.run {
          isUpdatingOwner = false
          isUpdateCompleted = true
          checkEffectActive = true
        }
        
        // 3) 2초 유지
        try? await Task.sleep(for: .seconds(2))
        await MainActor.run {
          dismiss()
        }
      } catch {
        await MainActor.run {
          isUpdatingOwner = false
          isUpdateCompleted = false
          checkEffectActive = false
        }
        print("updateTeamspaceOwner error: \(error.localizedDescription)")
      }
    }
  }
}

#Preview {
  MemberManagementView(
    viewModel: TeamspaceSettingViewModel(),
    user: .init(
      userId: "dummy",
      email: "dummy@example.com",
      name: "홍길동",
      loginType: .apple,
      fcmToken: "",
      termsAgreed: true,
      privacyAgreed: true
    )
  )
}
