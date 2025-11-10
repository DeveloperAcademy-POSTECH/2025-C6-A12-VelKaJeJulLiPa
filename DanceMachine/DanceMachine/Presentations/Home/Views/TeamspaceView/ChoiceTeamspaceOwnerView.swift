//
//  ChoiceTeamspaceOwnerView.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/9/25.
//

import SwiftUI

struct ChoiceTeamspaceOwnerView: View {
  
  @Environment(\.dismiss) private var dismiss
  
  @Bindable var viewModel: TeamspaceSettingViewModel
  
  @Binding var users: [User]
  
  @State private var selectedUser: User? // 선택 팀원 (owner 설정할 팀원)
  
  var body: some View {
    ZStack {
      Color.backgroundElevated.ignoresSafeArea()
      VStack {
        Spacer().frame(height: 29)
        topTitleView
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 16)
        Spacer().frame(height: 32)
        inputTeamspaceNameView
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 16)
        Spacer()
        bottomButtonView
          .padding(.horizontal, 16)
      }
    }
  }
  
  // MARK: - 탑 타이틀
  private var topTitleView: some View {
    ZStack { // TODO: 서치
      // 가운데 정렬 타이틀
      Text("팀장 선택하기")
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
          .onTapGesture { dismiss() }
        Spacer()
      }
    }
  }
  
  
  // MARK: - 팀 스페이스 텍스트 필드 뷰 ("팀 스페이스 이름" + 텍스트 필드)
  private var inputTeamspaceNameView: some View {
    VStack {
      Text("팀을 이어갈 팀장을 선택해주세요.")
        .font(.title2SemiBold)
        .foregroundStyle(Color.labelStrong)
      
      Spacer().frame(height: 24)
      
      Text("팀원")
        .font(.headline2SemiBold)
        .foregroundStyle(Color.labelAssitive)
        .frame(maxWidth: .infinity, alignment: .leading)
      
      Spacer().frame(height: 16)
      
      List(users.filter { user in
        // 내 아이디와 같은 user는 제외
        user.userId != FirebaseAuthManager.shared.userInfo?.userId ?? ""
      }, id: \.userId) { user in
        LabeledContent {
          // 선택된 유저면 체크 이미지 표시
          if selectedUser?.userId == user.userId {
            Image(systemName: "checkmark.circle.fill")
              .resizable()
              .scaledToFit()
              .frame(width: 24, height: 24)
              .foregroundStyle(Color.secondaryAssitive)
          }
        } label: {
          Text(user.name)
            .font(.headline2Medium)
            .foregroundStyle(Color.labelStrong)
        }
        .background(Color.backgroundElevated)
        .contentShape(Rectangle())
        .simultaneousGesture(
          TapGesture().onEnded {
            // 같은 셀 다시 누르면 선택 해제하고 싶으면 토글로
            if selectedUser?.userId == user.userId {
              selectedUser = nil
            } else {
              selectedUser = user
            }
          }
        )
        .listRowBackground(Color.backgroundElevated)
        .listRowInsets(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8))
        .listRowSeparatorTint(Color.strokeStrong)
      }
      .listStyle(.plain)
    }
  }
  
  // MARK: - 바텀 팀 스페이스 만들기 뷰
  private var bottomButtonView: some View {
    ActionButton(
      title: "팀장으로 선택",
      color: self.selectedUser == nil ? Color.fillAssitive : Color.secondaryStrong,
      height: 47,
      isEnabled: self.selectedUser == nil ? false : true
    ) {
      Task {
        // 1. 선택된 팀원을 현재 팀 스페이스 ownerId로 교체한다.
        try await viewModel.updateTeamspaceOwner(userId: self.selectedUser?.userId ?? "")
        // 2. 구 owenr를 팀 스페이스에서 제외 시킨다.
        // 3. 현재 유저의 계정 서브컬렉션에 해당 팀 스페이스를 제거 시킨다.
        try await viewModel.leaveTeamspace()
        dismiss()
        dismiss()
      }
    }
    .padding(.bottom, 16)
  }
}


#Preview {
  ChoiceTeamspaceOwnerView(
    viewModel: TeamspaceSettingViewModel(),
    users: .constant([])
  )
}
