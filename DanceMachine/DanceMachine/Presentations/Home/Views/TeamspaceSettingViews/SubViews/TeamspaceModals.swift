//
//  TeamspaceModals.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/19/25.
//

import SwiftUI

// MARK: - 레이아웃 상수

fileprivate enum TeamspaceModalsLayout {
  
  // 공통 안내 문구
  enum Common {
    static let reInviteMessage: String = "이후 다시 초대할 수 있습니다."
    static let leaveMessage: String = "다시 초대받아 참여할 수 있습니다."
  }
  
  // 팀원(뷰어)이 팀 스페이스 나가기
  enum MemberLeave {
    static let titleSuffix: String = " 팀 스페이스를 나가시겠어요?"
    static let cancelTitle: String = "취소"
    static let leaveTitle: String = "나가기"
  }
  
  // 팀장(오너)이 팀 스페이스 나가기 시도했을 때
  enum OwnerLeave {
    static let titleSuffix: String = "팀 스페이스를 나가시겠어요?"
    static let okTitle: String = "확인"
    static let message: String = "팀 스페이스에서 나가려면 팀장 권한을 다른 팀원에게 양도해야 합니다."
  }
  
  // 팀 스페이스 완전 삭제
  enum DeleteTeamspace {
    static let titleSuffix: String = " 팀 스페이스를 삭제하시겠어요?"
    static let cancelTitle: String = "취소"
    static let deleteTitle: String = "삭제하기"
    static let message: String = "팀 스페이스와 멤버 목록이 모두 초기화됩니다."
  }
  
  // 단일 팀원 내보내기
  enum SingleMemberRemoval {
    static let titleSuffix: String = " 팀원을 내보내시겠어요?"
    static let cancelTitle: String = "취소"
    static let removeTitle: String = "내보내기"
  }
  
  // 여러 팀원 묶음 내보내기
  enum BulkMemberRemoval {
    static let title: String = "선택한 팀원들을 내보내시겠어요?"
    static let cancelTitle: String = "취소"
    static let removeTitle: String = "내보내기"
  }
}

// MARK: - 팀 스페이스 관련 Alert / Sheet 모음

extension View {
  
  /// 팀 스페이스 설정 화면에서 사용하는 Alert / Sheet 를 한 곳에 모아 적용하는 Modifier 입니다.
  /// - Parameters:
  ///   - viewModel: 팀 스페이스 설정 뷰모델
  ///   - router: 화면 이동을 담당하는 라우터
  func teamspaceModals(
    @Bindable _ viewModel: TeamspaceSettingViewModel,
    router: MainRouter
  ) -> some View {
    self
    
    // MARK: - 팀원(뷰어) 기준: 팀 스페이스 나가기 Alert
    
    // 현재 팀 스페이스에서 나가기를 눌렀을 때,
    // - 뷰어(viewer)라면: 해당 팀 스페이스에서 나가고, 다른 팀 스페이스로 이동하거나 팝
    // - 오너(owner)라면: 전체 팀 스페이스 삭제 로직으로 처리
      .alert(
        "\(viewModel.currentTeamspace?.teamspaceName ?? "")\(TeamspaceModalsLayout.MemberLeave.titleSuffix)",
        isPresented: $viewModel.teamspaceSettingPresentationState.isPresentingMemberLeaveTeamspaceAlert
      ) {
        Button(TeamspaceModalsLayout.MemberLeave.cancelTitle, role: .cancel) {}
        Button(TeamspaceModalsLayout.MemberLeave.leaveTitle, role: .destructive) {
          Task {
            switch viewModel.dataState.teamspaceRole {
            case .viewer:
              viewModel.dataState.loading = true
              defer { viewModel.dataState.loading = false }
              try await viewModel.leaveTeamspace()
              await MainActor.run { router.pop() }
            case .owner:
              try await viewModel.removeTeamspaceAndDetachFromAllUsers()
              await MainActor.run { router.pop() }
            }
          }
        }
      } message: {
        Text(TeamspaceModalsLayout.Common.leaveMessage)
      }
    
    // MARK: - 팀장(오너) 기준: 나가기 불가 안내 Alert
    
    // 팀장(오너)이 "팀 스페이스 나가기"를 시도했을 때,
    // 권한을 다른 팀원에게 양도해야 한다는 안내만 보여주는 Alert 입니다.
      .alert(
        "\(viewModel.currentTeamspace?.teamspaceName ?? "")\(TeamspaceModalsLayout.OwnerLeave.titleSuffix)",
        isPresented: $viewModel.teamspaceSettingPresentationState.isPresentingOwnerLeaveTeamspaceAlert
      ) {
        Button(TeamspaceModalsLayout.OwnerLeave.okTitle, role: .cancel) {}
      } message: {
        Text(TeamspaceModalsLayout.OwnerLeave.message)
      }
    
    // MARK: - 팀 스페이스 삭제 Alert
    
    // 팀 스페이스 자체를 완전히 삭제할 때 사용하는 Alert 입니다.
    // - 팀 스페이스 문서 / 멤버 목록 / 프로젝트 등을 전부 정리하고,
    // - 삭제 후 상위 화면으로 이동합니다.
      .alert(
        "\(viewModel.currentTeamspace?.teamspaceName ?? "")\(TeamspaceModalsLayout.DeleteTeamspace.titleSuffix)",
        isPresented: $viewModel.teamspaceSettingPresentationState.isPresentingDeleteTeamspaceAlert
      ) {
        Button(TeamspaceModalsLayout.DeleteTeamspace.cancelTitle, role: .cancel) {}
        Button(TeamspaceModalsLayout.DeleteTeamspace.deleteTitle, role: .destructive) {
          Task {
            viewModel.dataState.loading = true
            defer { viewModel.dataState.loading = false }
            try await viewModel.removeTeamspaceAndDetachFromAllUsers()
            await MainActor.run { router.pop() }
          }
        }
      } message: {
        Text(TeamspaceModalsLayout.DeleteTeamspace.message)
      }
    
    // MARK: - 단일 팀원 내보내기 Alert
    
    // 리스트에서 한 명의 팀원을 선택해 "팀에서 내보내기" 할 때 사용하는 Alert 입니다.
    // - teamspace/{id}/members 서브컬렉션과
    // - users/{userId}/userTeamspace 서브컬렉션에서 모두 제거합니다.
      .alert(
        "\(viewModel.teamspaceSettingPresentationState.selectedUserForRemoval?.name ?? "")\(TeamspaceModalsLayout.SingleMemberRemoval.titleSuffix)",
        isPresented: $viewModel.teamspaceSettingPresentationState.isPresentingChoiceMemberRemovalAlert
      ) {
        Button(TeamspaceModalsLayout.SingleMemberRemoval.cancelTitle, role: .cancel) {
          viewModel.teamspaceSettingPresentationState.selectedUserForRemoval = nil
        }
        Button(TeamspaceModalsLayout.SingleMemberRemoval.removeTitle, role: .destructive) {
          Task {
            
            viewModel.dataState.loading = true
            
            defer { viewModel.dataState.loading = false }
            
            guard let targetUser = viewModel.teamspaceSettingPresentationState.selectedUserForRemoval else {
              print("targetUser 오류")
              return
            }
            print("targetUser: \(targetUser)")
            
            do {
              let users = try await viewModel.removeTeamMemberAndReload(userId: targetUser.userId)
              //              await MainActor.run {
              viewModel.dataState.users = users
              viewModel.teamspaceSettingPresentationState.selectedUserForRemoval = nil
              // }
            } catch {
              print("single member remove error: \(error.localizedDescription)")
            }
          }
        }
      } message: {
        Text(TeamspaceModalsLayout.Common.reInviteMessage)
      }
    
    // MARK: - 여러 팀원 묶음 내보내기 Alert
    
    // 삭제 모드에서 여러 팀원을 선택 후 "내보내기" 버튼을 눌렀을 때 사용하는 Alert 입니다.
    // 선택된 모든 유저에 대해 teamspace / users 서브컬렉션에서 참조를 제거합니다.
      .alert(
        TeamspaceModalsLayout.BulkMemberRemoval.title,
        isPresented: $viewModel.teamspaceSettingPresentationState.isPresentingMemberRemovalAlert
      ) {
        Button(TeamspaceModalsLayout.BulkMemberRemoval.cancelTitle, role: .cancel) {
          viewModel.teamspaceSettingPresentationState.selectedUserForRemoval = nil
        }
        Button(TeamspaceModalsLayout.BulkMemberRemoval.removeTitle, role: .destructive) {
          Task {
            await viewModel.removeSelectedMembers()
          }
        }
      } message: {
        Text(TeamspaceModalsLayout.Common.reInviteMessage)
      }
    
    // MARK: - 팀원 관리 시트 (한 명 대상)
    
    // 팀원 리스트에서 점(...) 버튼을 눌렀을 때,
    // - 해당 팀원에 대한 팀장 위임 / 팀에서 내보내기 등을 처리하는 Half Sheet 입니다.
      .sheet(
        isPresented: $viewModel.teamspaceSettingPresentationState.isPresentingMemberManagementSheet
      ) {
        if let target = viewModel.teamspaceSettingPresentationState.selectedUserForRemoval {
          MemberManagementView(
            viewModel: viewModel,
            user: target,
            onCompleted: {
              Task {
                await viewModel.onAppear()
              }
            }
          )
          .appHalfSheetStyle()
        }
      }
    
    // MARK: - 새 팀 스페이스 생성 시트
    
    // 새 팀 스페이스를 생성하는 시트입니다.
    // 시트가 닫힐 때 onAppear를 다시 호출해,
    // - 현재 팀스페이스 / 멤버 리스트 등의 상태를 갱신합니다.
      .sheet(
        isPresented: $viewModel.teamspaceSettingPresentationState.isPresentingCreateTeamspaceSheet
      ) {
        CreateTeamspaceView(
          presentationStyle: .sheet
        )
        .appSheetStyle()
        .onDisappear {
          Task {
            await viewModel.onAppear()
          }
        }
      }
    
    // MARK: - 팀 스페이스 이름 수정 시트
    
    // 팀 스페이스 이름을 변경하는 시트입니다.
    // 변경 후에는 viewModel 내부에서 currentTeamspace / selectedTeamspaceName 을 동기화합니다.
      .sheet(
        isPresented: $viewModel.teamspaceSettingPresentationState.isPresentingUpdateTeamspaceNameSheet
      ) {
        TeamspaceNameUpdateView(viewModel: viewModel)
          .appSheetStyle()
      }
  }
}
