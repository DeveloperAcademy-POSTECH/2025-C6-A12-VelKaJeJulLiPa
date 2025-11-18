//
//  TeamspaceSettingViewModelState.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/19/25.
//

import Foundation

/// 팀 셋팅 뷰에서 리스트/권한 등을 담당하는 데이터 상태입니다.
struct TeamspaceSettingDataState {
  var loading: Bool = false
  var selectedTeamspaceName: String = "불러오는중..."
  var users: [User] = []
  var teamspaceRole: TeamspaceRole = .viewer
  var memberListMode: MemberListMode = .browsing
  
  var selectedUserIdsForRemoval: Set<String> = [] // 삭제용
}

/// 팀 셋팅 뷰에서 팀 스페이스를 불러올 데이터 상태입니다.
struct TeamspaceChoiceState {
  var teamspace: [Teamspace] = []
  var loading: Bool = false
}

/// 알럿 / 시트 등의 프레젠테이션 상태입니다.
struct TeamspaceSettingPresentationState {
  // Alert
  var isPresentingMemberLeaveTeamspaceAlert: Bool = false     // 팀 스페이스 나가기 (팀원)
  var isPresentingOwnerLeaveTeamspaceAlert: Bool = false      // 팀 스페이스 나가기 (팀장)
  var isPresentingDeleteTeamspaceAlert: Bool = false          // 팀 스페이스 삭제
  var isPresentingMemberRemovalAlert: Bool = false            // 팀원 내보내기 (전체)
  var isPresentingChoiceMemberRemovalAlert: Bool = false      // 선택된 팀원

  // Alert 에서 사용할 선택된 유저
  var selectedUserForRemoval: User? = nil
  
  // Sheet
  var isPresentingCreateTeamspaceSheet: Bool = false      // 새 팀 스페이스 만들기
  var isPresentingUpdateTeamspaceNameSheet: Bool = false  // 팀 스페이스 이름 수정
  var isPresentingMemberManagementSheet: Bool = false     // 멤버 관리 시트 (추방 + 팀장 위임)
}
