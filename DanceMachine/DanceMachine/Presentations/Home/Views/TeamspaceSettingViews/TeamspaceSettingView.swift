//
//  TeamspaceSettingView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/12/25.
//

import SwiftUI

struct TeamspaceSettingView: View {
  
  @EnvironmentObject private var rotuer: MainRouter
  
  @State private var viewModel: TeamspaceSettingViewModel = .init()

  fileprivate enum NameSpace {
    enum Top {
      static let inviteTitle: String = "팀에 멤버 초대하기"
    }
    enum MemberHeader {
      static let title: String = "팀원"
      static let cancelTitle: String = "취소"
      static let removeTitle: String = "내보내기"
    }
    enum MemberRow {
      static let ownerBadgeTitle: String = "팀장"
      static let ellipsisSystemName: String = "ellipsis"
    }
    enum Bottom {
      static let leaveTeamspaceTitle: String = "팀 스페이스 나가기"
      static let deleteTeamspaceTitle: String = "팀 스페이스 삭제하기"
    }
  }
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      
      VStack {
        Spacer().frame(height: 22)
        topTeamspaceSettingView.padding(.horizontal, 16)
        Spacer().frame(height: 16)
        memberHeaderView
        memberListView
        Spacer()
        ThickDivider()
        Spacer().frame(height: 30)
        bottomDeleteTeamspaceView.padding(.horizontal, 16)
      }
      // 로딩 오버레이
      if viewModel.dataState.loading {
        Color.backgroundNormal.ignoresSafeArea()
        LoadingSpinner()
          .frame(width: 28, height: 28)
      }
    }
    .toolbar {
      ToolbarLeadingBackButton(icon: .chevron)
      TeamspaceSettingViewToolbar(viewModel: viewModel)
    }
    .task {
      if ProcessInfo.isRunningInPreviews { return } // 프리뷰 전용
      await viewModel.onAppear()
    }
    .onDisappear {
      // 화면 사라질 때, 선택 유저 초기화
      viewModel.teamspaceSettingPresentationState.selectedUserForRemoval = nil
    }
    .teamspaceModals(viewModel, router: rotuer) // 모달
  }
  
  // MARK: - 탑 팀 멤버 초대하기
  private var topTeamspaceSettingView: some View {
    VStack {
      ActionButton(
        title: NameSpace.Top.inviteTitle,
        color: Color.secondaryStrong,
        height: 47,
        isEnabled: viewModel.dataState.memberListMode == .browsing ? true : false
      ) {
        Task {
          guard let item = await viewModel.makeInviteShareItem() else { return }
          await MainActor.run {
            let viewController = UIActivityViewController(
              activityItems: [item],
              applicationActivities: nil
            )
            UIApplication.shared.topMostViewController()?.present(viewController, animated: true)
          }
        }
      }
    }
  }
  
  // MARK: - 팀원 헤더 뷰 (타이틀 + 내보내기/취소 버튼)
  private var memberHeaderView: some View {
    LabeledContent {
      memberHeaderRightContent
    } label: {
      memberHeaderLeftContent
    }
    .padding(.horizontal, 16)
  }
  
  // 팀원 헤더 왼쪽 뷰 (타이틀)
  private var memberHeaderLeftContent: some View {
    Text(NameSpace.MemberHeader.title)
      .font(.headline2SemiBold)
      .foregroundStyle(Color.labelAssitive)
  }
  
  // 팀원 헤더 오른쪽 뷰 (역할 따라 분기) - Viewer / Owner
  @ViewBuilder
  private var memberHeaderRightContent: some View {
    switch viewModel.dataState.teamspaceRole {
    case .viewer:
      EmptyView()
    case .owner:
      memberHeaderOwnerContent
    }
  }
  
  // 오너일 때 헤더 오른쪽 (모드에 따라 분기)
  @ViewBuilder
  private var memberHeaderOwnerContent: some View {
    switch viewModel.dataState.memberListMode {
    case .browsing:
      // 팀원 목록만 보는 모드 - 헤더 오른쪽에는 액션 없음
      EmptyView()
    case .removing:
      // 팀원 삭제 모드 - 취소 / 내보내기 버튼 표시
      HStack {
        // 선택 초기화 + 브라우징 모드로 복귀
        Button {
          viewModel.dataState.selectedUserIdsForRemoval = []
          viewModel.dataState.memberListMode = .browsing
        } label: {
          Text(NameSpace.MemberHeader.cancelTitle)
            .font(.headline2SemiBold)
            .foregroundStyle(Color.labelStrong)
        }
        
        // 선택된 팀원이 있을 때만 활성화되는 내보내기 버튼
        UpdateButton(
          title: NameSpace.MemberHeader.removeTitle,
          titleColor: Color.accentRedNormal,
          isEnabled: !viewModel.dataState.selectedUserIdsForRemoval.isEmpty
        ) {
          viewModel.teamspaceSettingPresentationState.isPresentingMemberRemovalAlert = true
        }
      }
    }
  }

  // MARK: - 팀원 리스트 뷰
  private var memberListView: some View {
    List(viewModel.dataState.users, id: \.userId) { user in
      LabeledContent {
        memberRowTrailingView(for: user)   // 오른쪽(버튼/체크박스) 영역
      } label: {
        memberRowLeadingView(for: user)    // 왼쪽(이름/팀장 뱃지) 영역
      }
      .teamMemberRowStyle()
    }
    .listStyle(.plain)
  }

  // 팀원 셀 왼쪽 뷰 (이름 + 팀장 뱃지)
  @ViewBuilder
  private func memberRowLeadingView(for user: User) -> some View {
    HStack(spacing: 10) {
      Text(user.name)
        .font(.headline2Medium)
        .foregroundStyle(Color.labelStrong)
      
      if user.userId == viewModel.currentTeamspace?.ownerId ?? "" {
        Text(NameSpace.MemberRow.ownerBadgeTitle)
          .font(.headline2SemiBold)
          .foregroundStyle(Color.secondaryStrong)
          .padding(.horizontal, 6)
          .padding(.vertical, 3.5)
          .background(
            Capsule()
              .fill(Color.fillSubtle)
          )
      }
    }
  }

  // 팀원 셀 오른쪽 뷰 (점 3개 버튼 / 체크박스)
  @ViewBuilder
  private func memberRowTrailingView(for user: User) -> some View {
    switch viewModel.dataState.memberListMode {
    case .browsing:
      // 1) 내가 팀스페이스 owner이고
      // 2) 이 row의 user가 팀장(=ownerId)이 아닐 때만 점 3개 버튼 노출
      if viewModel.dataState.teamspaceRole == .owner,
         user.userId != viewModel.currentTeamspace?.ownerId {
        
        Button {
          viewModel.teamspaceSettingPresentationState.selectedUserForRemoval = user
          viewModel.teamspaceSettingPresentationState.isPresentingMemberManagementSheet = true
        } label: {
          ZStack {
            Rectangle()
              .fill(Color.clear)
            
            Image(systemName: NameSpace.MemberRow.ellipsisSystemName)
              .font(.system(size: 17, weight: .medium))
              .foregroundStyle(Color.labelNormal)
          }
          .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        
      } else {
        EmptyView()
      }
      
    case .removing:
      if viewModel.currentTeamspace?.ownerId == user.userId {
        EmptyView()
      } else {
        CheckCircleButton(
          isSelected: viewModel.dataState.selectedUserIdsForRemoval.contains(user.userId)
        ) {
          viewModel.toggleSelectionForRemoval(user: user)
        }
      }
    }
  }
  
  // MARK: - 바텀 팀 스페이스 삭제/나가기 뷰
  private var bottomDeleteTeamspaceView: some View {
    VStack {
      switch viewModel.dataState.teamspaceRole {
      case .viewer:
        Button {
          viewModel.teamspaceSettingPresentationState.isPresentingMemberLeaveTeamspaceAlert = true
        } label: {
          Text(NameSpace.Bottom.leaveTeamspaceTitle)
            .font(.headline2Medium)
            .foregroundStyle(Color.accentRedNormal)
        }
        
        Spacer().frame(height: 68)
        
      case .owner:
        // 스페이스 인원이 2명 이상일때만 나가기 버튼 생김
        if viewModel.dataState.users.count > 1 {
          Button {
            viewModel.teamspaceSettingPresentationState.isPresentingOwnerLeaveTeamspaceAlert = true
          } label: {
            Text(NameSpace.Bottom.leaveTeamspaceTitle)
              .font(.headline2Medium)
              .foregroundStyle(Color.accentRedNormal)
          }
          Spacer().frame(height: 32)
        }
        Button {
          viewModel.teamspaceSettingPresentationState.isPresentingDeleteTeamspaceAlert = true
        } label: {
          Text(NameSpace.Bottom.deleteTeamspaceTitle)
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
      .environmentObject(MainRouter())
  }
}
