//
//  TeamspaceSettingView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/12/25.
//

import SwiftUI

// TODO: Owner 팀 나가기 케이스 추가하기
struct TeamspaceSettingView: View {
  
  @EnvironmentObject private var rotuer: NavigationRouter
  
  @State private var viewModel: TeamspaceSettingViewModel = .init()
  @State private var editingState: EditingState = .viewing
  @State private var teamspaceRole: TeamspaceRole = .viewer
  @State private var memberListMode: MemberListMode = .browsing
  
  @State private var users: [User] = [] // 유저 정보
  
  @State private var isPresentingLeaveTeamspaceAlert: Bool = false // 팀 스페이스 나가기 Alert 제어
  @State private var isPresentingDeleteTeamspaceAlert: Bool = false // 팀 스페이스 삭제 Alert 제어
  
  @State private var presentingMemberRemovalAlertUser: Bool = false // 팀원 방출 alert
  @State private var selectedUser: User? // 팀원 방출 해당 유저
  
  // 수정하기 변수
  @State private var editedName: String = ""
  @FocusState private var nameFieldFocused: Bool
  
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea() // FIXME: - 컬러 수정
      
      VStack {
        topTeamspaceSettingView.padding(.horizontal, 16)
        Spacer().frame(height: 32)
        Divider()
        Spacer().frame(height: 32)
        middleTeamMemberManagementView
        Spacer()
        ThickDivider()
        Spacer().frame(height: 30)
        bottomDeleteTeamspaceView.padding(.horizontal, 16)
      }
    }
    .alert(
      "\(viewModel.currentTeamspace?.teamspaceName ?? "") 팀 스페이스를 나가시겠어요?",
      isPresented: $isPresentingLeaveTeamspaceAlert
    ) {
      Button("취소", role: .cancel) {}
      Button("나가기", role: .destructive) {
        switch teamspaceRole {
        case .viewer:
          Task {
            try await viewModel.leaveTeamspace()
            await MainActor.run { rotuer.pop() }
          }
        case .owner:
          // FIXME: - 여기 로직 수정
          Task {
            try await viewModel.removeTeamspaceAndDetachFromAllUsers() // FIXME: - 로직 수정
            await MainActor.run { rotuer.pop() }
          }
        }
      }
    } message: {
      Text("다시 초대받아 참여할 수 있습니다.")
    }
    .alert(
      "\(viewModel.currentTeamspace?.teamspaceName ?? "") 팀 스페이스를 삭제하시겠어요?",
      isPresented: $isPresentingDeleteTeamspaceAlert) {
        Button("취소", role: .cancel) {}
        Button("나가기", role: .destructive) {
          Task {
            try await viewModel.removeTeamspaceAndDetachFromAllUsers() // FIXME: - 로직 수정
            await MainActor.run { rotuer.pop() }
          }
        }
      } message: {
        Text("팀 스페이스와 멤버 목록이 모두 초기화됩니다.")
      }
    .alert(
      "\(self.selectedUser?.name ?? "") 팀원을 내보내시겠어요?",
      isPresented: $presentingMemberRemovalAlertUser
    ) {
      Button("취소", role: .cancel) {
        self.selectedUser = nil
      }
      Button("내보내기", role: .destructive) {
        Task {
          let users: [User] = try await viewModel.removeTeamMemberAndReload(userId: selectedUser?.userId ?? "")
          await MainActor.run {
            self.users = users
            self.selectedUser = nil
          }
        }
      }
    } message: {
      Text("이후 다시 초대할 수 있습니다.")
    }
    .toolbar {
      ToolbarLeadingBackButton(icon: .chevron)
      ToolbarCenterTitle(text: "팀 스페이스 설정")
    }
    .task {
      print("시작")
      
      if ProcessInfo.isRunningInPreviews { return } // 프리뷰 전용
      
      // 로그인 유저와 팀 스페이스 ownerId가 일치하면 발생하는 로직 => 팀 스페이스 주인 => 권한 up
      await MainActor.run {
        self.teamspaceRole = viewModel.isTeamspaceOwner() ? .owner : .viewer
      }
      
      let users: [User] = await viewModel.fetchCurrentTeamspaceAllMember()
      self.users = users
    }
  }
  
  // MARK: - 탑 팀 스페이스 설정 뷰 (팀 이름 수정하기 + 팀 멤버 초대하기)
  private var topTeamspaceSettingView: some View {
    VStack(alignment: .leading) {
      LabeledContent {
        switch teamspaceRole {
        case .viewer:
          EmptyView()
        case .owner:
          switch editingState {
          case .viewing:
            if self.memberListMode == .browsing { // 팀원 삭제중에는 수정하기 버튼이 보이지 않도록 수정
              UpdateButton(
                title: "수정하기",
                titleColor: Color.primitiveNormal) {
                  self.editedName = viewModel.currentTeamspace?.teamspaceName ?? ""
                  self.editingState = .editing
                  self.nameFieldFocused = true
                }
            }
          case .editing:
            UpdateButton(
              title: "완료",
              titleColor: Color.accentBlueStrong) {
                Task {
                  try await viewModel.renameCurrentTeamspaceAndReload(editedName: self.editedName)
                  await MainActor.run {
                    self.editingState = .viewing
                    self.nameFieldFocused = false
                  }
                }
              }
              .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          }
        }
      } label: {
        Text("팀 이름")
          .font(.headline2SemiBold)
          .foregroundStyle(Color.labelAssitive)
      }
      Spacer().frame(height: 16)
      switch editingState {
      case .viewing:
        Text(viewModel.currentTeamspace?.teamspaceName ?? "")
          .font(.title2SemiBold)
          .foregroundStyle(.labelStrong)
      case .editing:
        TextField("팀 이름을 입력하세요", text: $editedName)
          .font(.title2SemiBold)
          .foregroundStyle(Color.labelStrong)
          .tint(Color.secondaryNormal)
          .focused($nameFieldFocused)
          .submitLabel(.return)
          .onSubmit {
            // 키보드만 내려가게
            //                        Task {
            //                            try await viewModel.renameCurrentTeamspaceAndReload(editedName: self.editedName)
            //                            await MainActor.run {
            //                                self.editingState = .viewing
            //                                self.nameFieldFocused = false
            //                            }
            //                        }
          }
        Rectangle()
          .fill(Color.secondaryNormal)
          .frame(height: 1)
      }
      Spacer().frame(height: 32)
      ActionButton(
        title: "팀에 멤버 초대하기",
        color: self.editingState == .viewing ? Color.secondaryStrong : Color.fillAssitive, // FIXME: - 컬러 수정
        height: 47,
        isEnabled: self.editingState == .viewing ? true : false,
        action: {
          switch self.editingState {
          case .viewing: // 팀원 초대하기
            print("팀원 초대하기")
            Task {
              // 1) 현재 팀스페이스 id 안전하게 가져오기
              guard let teamspaceId = viewModel.currentTeamspace?.teamspaceId.uuidString else {
                print("초대링크 생성 실패: teamspaceId 없음")
                return
              }
              
              guard let teamspaceName = viewModel.currentTeamspace?.teamspaceName else {
                print("팀 스페이스 이름 불러오기 실패")
                return
              }
              
              do {
                // 2) 초대 링크 생성
                let url = try await InviteService().createInvite(
                  teamspaceId: teamspaceId
                )
                
                // 3) 공유 시트 표시 (UI는 메인 스레드)
                await MainActor.run {
                  let item = InviteShareItem(teamName: teamspaceName, url: url)
                  let av = UIActivityViewController(activityItems: [item], applicationActivities: nil)
                  UIApplication.shared.topMostViewController()?.present(av, animated: true)
                }
              } catch {
                print("초대링크 생성 실패: \(error)")
              }
            }
            // TODO:
          case .editing: // 버튼 비활성화
            break
          }
        }
      )
    }
  }
  
  // MARK: - 미들 팀 멤버 관리 뷰
  private var middleTeamMemberManagementView: some View {
    VStack {
      LabeledContent {
        switch teamspaceRole {
        case .viewer:
          EmptyView()
        case .owner:
          switch memberListMode {
          case .browsing:
            if self.editingState == .viewing && self.users.count > 1 { // 팀 이름을 수정중이지 않을 때만 버튼 보이게 설정. || 팀 멤버가 나밖에 없을때 (팀스페이스 인원이 1명 이하일때 삭제버튼 hidden)
              // TODO: 피그마 보고 여기 처리.
              UpdateButton(
                title: "팀원 삭제",
                titleColor: Color.primitiveNormal) {
                  self.memberListMode = .removing
                }
            }
          case .removing:
            UpdateButton(
              title: "완료",
              titleColor: Color.secondaryStrong) { // FIXME: - 컬러 수정
                self.memberListMode = .browsing
              }
          }
        }
      } label: {
        Text("팀원")
          .font(.headline2SemiBold)
          .foregroundStyle(Color.labelAssitive)
      }
      .padding(.horizontal, 16)
      
      List(users, id: \.userId) { user in
        LabeledContent {
          switch memberListMode {
          case .browsing:
            EmptyView()
          case .removing:
            // 유저 멤버 중 팀스페이스 주인 아이디와 일치하면 이미지 x
            if viewModel.currentTeamspace?.ownerId == user.userId { EmptyView() }
            else {
              MinusCircleButton {
                print("MinusCircleButtonTapped")
                self.selectedUser = user
                self.presentingMemberRemovalAlertUser = true
                /*self.presentingMemberRemovalSheetUser = user*/ } }
          }
        } label: {
          Text(user.name)
            .font(.headline2Medium)
            .foregroundStyle(Color.labelStrong)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .frame(height: 48)
        .background(Color.backgroundNormal)
        .listRowBackground(Color.backgroundNormal)
        .listRowInsets(.init())
        .listRowSeparatorTint(Color.strokeNormal)
      }
      .listStyle(.plain)
    }
  }
  
  // MARK: - 바텀 팀 스페이스 삭제하기 뷰
  private var bottomDeleteTeamspaceView: some View {
    VStack {
      switch teamspaceRole {
      case .viewer:
        Button {
          self.isPresentingLeaveTeamspaceAlert = true
        } label: {
          Text("팀 스페이스 나가기")
            .font(.headline2Medium)
            .foregroundStyle(Color.accentRedNormal)
        }
        
        Spacer().frame(height: 32)
        
        Spacer().frame(height: 36)
        
      case .owner:
        Button {
          self.isPresentingLeaveTeamspaceAlert = true
        } label: {
          Text("팀 스페이스 나가기")
            .font(.headline2Medium)
            .foregroundStyle(Color.accentRedNormal)
        }
        
        Spacer().frame(height: 32)
        
        Button {
          self.isPresentingDeleteTeamspaceAlert = true
        } label: {
          Text("팀 스페이스 삭제하기")
            .font(.headline2Medium)
            .foregroundStyle(Color.accentRedStrong)
        }
        
        Spacer().frame(height: 36)
      }
    }
  }
}


#Preview {
  NavigationStack {
    TeamspaceSettingView()
      .environmentObject(NavigationRouter())
  }
}


/// Custom Alert
struct UnsavedChangesAlertView: View {
  let title: String
  let message: String
  let onCancel: () -> Void
  let onDelete: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      VStack(alignment: .leading, spacing: 8) {
        Text(title)
          .font(.pretendard(.semiBold, size: 20))   // 원하는 폰트
          .foregroundStyle(Color.white)
          .multilineTextAlignment(.leading)
        
        Text(message)
          .font(.pretendard(.medium, size: 15))
          .foregroundStyle(Color.white.opacity(0.8))
          .multilineTextAlignment(.leading)
      }
      
      HStack(spacing: 16) {
        Button(action: onCancel) {
          Text("취소")
            .font(.pretendard(.semiBold, size: 16))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
              Capsule()
                .fill(Color.gray.opacity(0.8))     // 취소 배경
            )
        }
        
        Button(action: onDelete) {
          Text("삭제")
            .font(.pretendard(.semiBold, size: 16))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
              Capsule()
                .fill(Color.red)                  // 삭제 배경
            )
        }
      }
    }
    .padding(24)
    .background(
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(Color.black.opacity(0.95))
    )
    .shadow(radius: 30)
    .padding(.horizontal, 24)
  }
}


