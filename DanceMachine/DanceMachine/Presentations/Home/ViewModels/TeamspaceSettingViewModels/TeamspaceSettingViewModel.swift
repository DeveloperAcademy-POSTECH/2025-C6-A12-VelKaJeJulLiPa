//
//  TeamspaceSettingViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/12/25.
//

import SwiftUI

protocol TeamspaceSettingViewModelProtocol: AnyObject {
  // 상태
  var currentTeamspace: Teamspace? { get }
  var dataState: TeamspaceSettingDataState { get set }
  var teamspaceChoiceState: TeamspaceChoiceState { get set }
  var teamspaceSettingPresentationState: TeamspaceSettingPresentationState { get set }
  var lastAccessedTeamspaceId: String { get }
  
  // 뷰 실행
  func onAppear() async
  
  // 초대 공유
  func makeInviteShareItem() async -> InviteShareItem?
  
  // 팀스페이스 선택/교체
  func fetchCurrentTeamspace(teamspace: Teamspace)
  func selectTeamspace(_ teamspace: Teamspace)
  func loadUserTeamspace() async
  
  // 팀스페이스 나가기 / 삭제 / 멤버 관리
  func leaveTeamspace() async throws
  func removeTeamMemberAndReload(userId: String) async throws -> [User]
  func removeTeamspaceAndDetachFromAllUsers() async throws
  
  // 멤버 선택/삭제 관련
  func toggleSelectionForRemoval(user: User)
  func clearSelectionAndExitRemovingMode()
  func removeSelectedMembers() async
}


@Observable
final class TeamspaceSettingViewModel: TeamspaceSettingViewModelProtocol {
  
  // 현재 선택된 팀 스페이스 (전역 FirebaseAuthManager와 연동)
  var currentTeamspace: Teamspace? { FirebaseAuthManager.shared.currentTeamspace }
  
  // TeamspaceSettingView 에서 사용하는 주요 상태
  var dataState = TeamspaceSettingDataState()
  
  // 툴바 팀 스페이스 선택 메뉴 상태
  var teamspaceChoiceState = TeamspaceChoiceState()
  
  // Alert / Sheet 등 프레젠테이션 상태
  var teamspaceSettingPresentationState = TeamspaceSettingPresentationState()
  
  // 최근 접속 팀 스페이스 아이디 (AppStorage)
  @ObservationIgnored
  @AppStorage(AppStorageKey.lastAccessedTeamspaceId.rawValue)
  private(set) var lastAccessedTeamspaceId: String = ""
  
  
  // MARK: - TeamspaceSettingView 관련 메서드
  // TeamspaceSettingView / TeamspaceSettingViewToolbar / TeamspaceModals 에서 사용하는 로직
  /// TeamspaceSettingView 가 등장할 때 초기 로딩을 담당합니다.
  /// - 역할:
  ///   1) 현재 팀 스페이스의 owner / viewer 역할 판별
  ///   2) 현재 팀 스페이스 멤버 목록 조회
  ///   3) 최근 접속 팀 스페이스 아이디 갱신
  ///   4) 선택된 팀 스페이스 이름 / 유저 리스트 상태 갱신
  func onAppear() async {
    self.dataState.loading = true
    defer { self.dataState.loading = false }
    
    guard let currentTeamspace = self.currentTeamspace else {
      print("🙅🏻‍♂️현재 팀 스페이스를 불러올 수 없습니다.")
      return
    }
    
    // 1) owner, member 판별
    await MainActor.run {
      self.dataState.teamspaceRole = self.isTeamspaceOwner() ? .owner : .viewer
    }
    
    // 2) member 조회
    let users = await fetchCurrentTeamspaceAllMember()
    
    // 3) lastAccessedTeamspaceId 현재 팀 스페이스 정보 넣기 (팀 스페이스 갱신용)
    self.lastAccessedTeamspaceId = currentTeamspace.teamspaceId.uuidString
    
    // 4) View에 유저 정보 갱신하기
    await MainActor.run {
      self.dataState.users = users
      self.dataState.selectedTeamspaceName = currentTeamspace.teamspaceName
    }
  }
  
  /// 초대 공유 시트를 띄우기 위해 사용하는 InviteShareItem 을 생성합니다.
  /// - 사용처: TeamspaceSettingView 상단 "팀에 멤버 초대하기" 버튼
  func makeInviteShareItem() async -> InviteShareItem? {
    // 1) 팀스페이스 id / 이름 체크
    guard let teamspaceId = currentTeamspace?.teamspaceId.uuidString else {
      print("초대링크 생성 실패: teamspaceId 없음")
      return nil
    }
    
    guard let teamspaceName = currentTeamspace?.teamspaceName else {
      print("팀 스페이스 이름 불러오기 실패")
      return nil
    }
    
    do {
      // 2) 초대 링크 생성
      let url = try await InviteService().createInvite(teamspaceId: teamspaceId)
      
      // 3) 공유 아이템 생성 후 반환
      return InviteShareItem(teamName: teamspaceName, url: url)
    } catch {
      print("초대링크 생성 실패: \(error)")
      return nil
    }
  }
  
  /// FirebaseAuthManager 의 현재 팀 스페이스를 교체합니다.
  /// - 사용처:
  ///   - 툴바에서 다른 팀 스페이스 선택 시
  ///   - 팀 스페이스 나가기 / 삭제 후 다음 팀 스페이스로 이동 시
  func fetchCurrentTeamspace(teamspace: Teamspace) {
    FirebaseAuthManager.shared.currentTeamspace = teamspace
    self.lastAccessedTeamspaceId = teamspace.teamspaceId.uuidString
  }
  
  /// 현재 팀 스페이스의 전체 멤버 정보를 조회합니다.
  /// - 사용처:
  ///   - onAppear()
  ///   - 팀원 삭제 후 리스트 새로고침
  func fetchCurrentTeamspaceAllMember() async -> [User] {
    do {
      let members: [Members] = try await FirestoreManager.shared.fetchAllFromSubcollection(
        under: .teamspace,
        parentId: self.currentTeamspace?.teamspaceId.uuidString ?? "",
        subCollection: .members
      )
      
      let userIds = members.map { $0.userId }
      var users: [User] = []
      
      for id in userIds {
        users.append(try await FirestoreManager.shared.get(id, from: .users))
      }
      
      // ㄱㄴㄷ순으로 정렬
      let sortedUsers = users.sorted {
        $0.name.compare($1.name, locale: Locale(identifier: "ko_KR")) == .orderedAscending
      }
      
      return sortedUsers
    } catch {
      print("error: \(error.localizedDescription)") // FIXME: - 에러에 맞게 로직 수정
      return []
    }
  }
  
  /// 선택 중인 팀스페이스를 변경할 때 사용됩니다.
  /// - 사용처: TeamspaceSettingViewToolbar 의 팀 스페이스 메뉴
  func selectTeamspace(_ teamspace: Teamspace) {
    FirebaseAuthManager.shared.currentTeamspace = teamspace
    self.lastAccessedTeamspaceId = teamspace.teamspaceId.uuidString
    self.teamspaceSettingPresentationState.isChangedTeamspace = true
  }
  
  /// 툴바 메뉴를 열 때, 현재 로그인 유저의 팀 스페이스 목록을 로드합니다.
  /// - 사용처: TeamspaceSettingViewToolbar 의 Menu label 버튼
  func loadUserTeamspace() async {
    do {
      self.teamspaceChoiceState.loading = true
      defer { self.teamspaceChoiceState.loading = false }
      
      guard let userId = FirebaseAuthManager.shared.userInfo?.userId else {
        print("error: userId nil")
        return
      }
      
      // 1) 서브컬렉션(UserTeamspace) 가져오기
      let userTeamspaces = try await fetchUserTeamspace(userId: userId)
      
      // 2) 해당 아이디들로 실제 Teamspace 컬렉션 조회
      let fetchedTeamspaces = try await fetchTeamspaces(userTeamspaces: userTeamspaces)
      
      // 3) 상태에 반영
      self.teamspaceChoiceState.teamspace = fetchedTeamspaces
      
    } catch {
      print("🙅🏻‍♂️ loadUserTeamspace error: \(error.localizedDescription)")
    }
  }
  
  /// 팀원이 팀 스페이스를 나가는 메서드 입니다.
  /// - 사용처: TeamspaceModals 의 "팀 스페이스 나가기" (viewer 케이스)
  func leaveTeamspace() async throws {
    do {
      // FIXME: - batch 추가하기
      try await self.removeUserFromCurrentTeamspace(userId: FirebaseAuthManager.shared.userInfo?.userId ?? "")
      
      /// updated_at 갱신하기
      try await FirestoreManager.shared.updateTimestampField(
        field: .update,
        in: .users,
        documentId: FirebaseAuthManager.shared.userInfo?.userId ?? ""
      )
      
      let userTeamspaces = try await self.fetchUserTeamspace(
        userId: FirebaseAuthManager.shared.userInfo?.userId ?? ""
      )
      let loadTeamspaces = try await self.fetchTeamspaces(userTeamspaces: userTeamspaces)
      
      if let firstTeamspace = loadTeamspaces.first {
        await MainActor.run {
          print("있음: \(firstTeamspace.teamspaceName)")
          self.fetchCurrentTeamspace(teamspace: firstTeamspace)
        }
      } else {
        await MainActor.run {
          print("leave 없음")
          FirebaseAuthManager.shared.currentTeamspace = nil
        }
      }
    } catch {
      print("error: \(error.localizedDescription)") // FIXME: - 에러에 맞게 로직 수정
    }
  }
  
  /// 팀원 내보내기 + 내보내진 팀원 서브컬렉션에서도 팀 스페이스 제거 + 팀 스페이스 현재 멤버 새로고침
  /// - 사용처: TeamspaceModals 의 단일 멤버 강퇴 알럿
  func removeTeamMemberAndReload(userId: String) async throws -> [User] {
    do {
      // FIXME: - batch 추가하기
      try await self.removingTeamspaceMember(userId: userId) // 팀원 내보내기
      
      try await FirestoreManager.shared.deleteFromSubcollection(
        under: .users,
        parentId: userId,
        subCollection: .userTeamspace,
        target: self.currentTeamspace?.teamspaceId.uuidString ?? ""
      ) // 내보내진 팀원 서브컬렉션에서도 팀 스페이스 제거
      
      // FIXME: - 테스트 필요
      /// 제거 유저 updated_at 갱신하기
      try await FirestoreManager.shared.updateTimestampField(
        field: .update,
        in: .users,
        documentId: userId
      )
      
      return await self.fetchCurrentTeamspaceAllMember()
    } catch {
      print("error: \(error.localizedDescription)") // FIXME: - 에러에 맞게 로직 수정
      return []
    }
  }
  
  /// 팀스페이스를 삭제하기 전에, 이 팀스페이스에 속한 모든 유저의
  /// users/{userId}/userTeamspace 에서 해당 팀스페이스 참조를 제거하고,
  /// teamspace/{id}/members 를 비운 뒤, teamspace 문서를 삭제합니다.
  /// - 사용처:
  ///   - TeamspaceModals 의 "팀 스페이스 삭제하기" 알럿
  ///   - 팀장(owner)이 팀 스페이스를 완전히 삭제하는 플로우
  func removeTeamspaceAndDetachFromAllUsers() async throws {
    do {
      // FIXME: - batch 추가하기
      let teamspaceId = self.currentTeamspace?.teamspaceId.uuidString ?? ""
      
      // 1) members 서브컬렉션에서 모든 멤버 조회
      let members: [Members] = try await FirestoreManager.shared.fetchAllFromSubcollection(
        under: .teamspace,
        parentId: teamspaceId,
        subCollection: .members
      )
      
      // 2) 유저 ID 중복 제거
      let userIds = Array(Set(members.map { $0.userId }))
      
      // 3) 모든 유저의 userTeamspace에서 teamspaceId 제거 (병렬 처리)
      try await withThrowingTaskGroup(of: Void.self) { group in
        for uid in userIds {
          group.addTask {
            try await FirestoreManager.shared.deleteFromSubcollection(
              under: .users,
              parentId: uid,
              subCollection: .userTeamspace,
              target: teamspaceId
            )
          }
        }
        try await group.waitForAll()
      }
      
      // 4) teamspace/{id}/members 모두 삭제
      try await FirestoreManager.shared.deleteAllDocumentsInSubcollection(
        under: .teamspace,
        parentId: teamspaceId,
        subCollection: .members
      )
      
      // 5) teamspace 문서 삭제
      try await FirestoreManager.shared.delete(
        collectionType: .teamspace,
        documentID: teamspaceId
      )
      
      // 해당 팀스페이스의 프로젝트를 모두 제거
      // FIXME: - Functions를 정말 진지하게 고려해보자 (연쇄 삭제 고려하기)
      // FIXME: - 곡, 비디오까지 전부 연쇄 삭제를 넣어야 함.
      try await FirestoreManager.shared.deleteAllDocuments(
        from: .project,
        whereField: Project.CodingKeys.teamspaceId.stringValue,
        isEqualTo: teamspaceId
      )
      
      // FIXME: - 테스트 필요
      /// 제거 유저 updated_at 갱신하기
      try await FirestoreManager.shared.updateTimestampField(
        field: .update,
        in: .users,
        documentId: FirebaseAuthManager.shared.userInfo?.userId ?? ""
      )
      
      let userTeamspaces = try await self.fetchUserTeamspace(
        userId: FirebaseAuthManager.shared.userInfo?.userId ?? ""
      )
      let loadTeamspaces = try await self.fetchTeamspaces(userTeamspaces: userTeamspaces)
      
      if let firstTeamspace = loadTeamspaces.first {
        await MainActor.run {
          self.fetchCurrentTeamspace(teamspace: firstTeamspace)
        }
      }
      
    } catch {
      print("error: \(error.localizedDescription)")
    }
  }
  
  /// 삭제 대상으로 선택/해제 토글
  /// - 사용처: TeamspaceSettingView 의 체크박스 토글
  func toggleSelectionForRemoval(user: User) {
    let id = user.userId
    if dataState.selectedUserIdsForRemoval.contains(id) {
      dataState.selectedUserIdsForRemoval.remove(id)
    } else {
      dataState.selectedUserIdsForRemoval.insert(id)
    }
  }
  
  /// 선택 모두 해제 + 브라우징 모드로 복귀
  /// - 사용처: TeamspaceSettingView 상단 "취소" 버튼 및 삭제 완료 후
  func clearSelectionAndExitRemovingMode() {
    dataState.selectedUserIdsForRemoval.removeAll()
    dataState.memberListMode = .browsing
  }
  
  /// 선택된 멤버들 전부 내보내고 리스트 갱신
  /// - 사용처: TeamspaceModals 의 "선택한 팀원들을 내보내시겠어요?" 알럿
  func removeSelectedMembers() async {
    do {
      guard let teamspaceId = self.currentTeamspace?.teamspaceId.uuidString else {
        print("removeSelectedMembers error: teamspaceId nil")
        return
      }
      
      let targetUserIds = Array(dataState.selectedUserIdsForRemoval)
      
      for userId in targetUserIds {
        // 1) teamspace/{teamspaceId}/members 에서 제거
        try await FirestoreManager.shared.deleteFromSubcollection(
          under: .teamspace,
          parentId: teamspaceId,
          subCollection: .members,
          target: userId
        )
        
        // 2) users/{userId}/userTeamspace 에서 해당 팀스페이스 제거
        try await FirestoreManager.shared.deleteFromSubcollection(
          under: .users,
          parentId: userId,
          subCollection: .userTeamspace,
          target: teamspaceId
        )
        
        // 3) 제거된 유저 updated_at 갱신
        try await FirestoreManager.shared.updateTimestampField(
          field: .update,
          in: .users,
          documentId: userId
        )
      }
      
      // 4) 전체 멤버 리스트 다시 불러오기
      let updatedUsers = await self.fetchCurrentTeamspaceAllMember()
      
      await MainActor.run {
        self.dataState.users = updatedUsers
        self.clearSelectionAndExitRemovingMode()
      }
      
    } catch {
      print("removeSelectedMembers error: \(error.localizedDescription)")
    }
  }
}

// MARK: - 공통 Firestore / 도메인 유틸
// 여러 뷰에서 공통으로 사용하는 헬퍼 메서드
extension TeamspaceSettingViewModel {
  
  /// 사용자가 "현재 팀스페이스"에서 탈퇴하며
  /// teamspace/members 와 users/userTeamspace 모두에서 참조를 제거합니다.
  /// - 사용처:
  ///   - leaveTeamspace()
  private func removeUserFromCurrentTeamspace(userId: String) async throws {
    // FIXME: - batch 추가하기
    // teamspace 서브컬렉션에서 유저를 제거
    try await FirestoreManager.shared.deleteFromSubcollection(
      under: .teamspace,
      parentId: self.currentTeamspace?.teamspaceId.uuidString ?? "",
      subCollection: .members,
      target: userId
    )
    
    // users 서브컬렉션에서 teamspace를 제거
    try await FirestoreManager.shared.deleteFromSubcollection(
      under: .users,
      parentId: userId,
      subCollection: .userTeamspace,
      target: self.currentTeamspace?.teamspaceId.uuidString ?? ""
    )
  }
  
  /// 특정 멤버를 현재 팀스페이스에서 제거하는 메서드입니다.
  /// - 사용처:
  ///   - removeTeamMemberAndReload(userId:)
  private func removingTeamspaceMember(userId: String) async throws {
    try await FirestoreManager.shared.deleteFromSubcollection(
      under: .teamspace,
      parentId: currentTeamspace?.teamspaceId.uuidString ?? "",
      subCollection: .members,
      target: userId
    )
  }
  
  /// 현재 로그인 유저의 팀스페이스 목록을 전부 가져옵니다.
  /// - Parameters:
  ///   - userId: 현재 로그인 유저의 UUID
  /// - 사용처:
  ///   - loadUserTeamspace()
  ///   - leaveTeamspace()
  ///   - removeTeamspaceAndDetachFromAllUsers()
  private func fetchUserTeamspace(userId: String) async throws -> [UserTeamspace] {
    return try await FirestoreManager.shared.fetchAllFromSubcollection(
      under: .users,
      parentId: userId,
      subCollection: .userTeamspace
    )
  }
  
  /// UserTeamspace 리스트를 기반으로 실제 Teamspace 도큐먼트들을 조회합니다.
  /// - Parameters:
  ///   - userTeamspaces: users/{userId}/userTeamspace 서브컬렉션
  /// - 사용처:
  ///   - loadUserTeamspace()
  ///   - leaveTeamspace()
  ///   - removeTeamspaceAndDetachFromAllUsers()
  private func fetchTeamspaces(userTeamspaces: [UserTeamspace]) async throws -> [Teamspace] {
    // 순서 보존하며 중복 제거
    var seen = Set<String>()
    let ids = userTeamspaces.compactMap { ut -> String? in
      if seen.insert(ut.teamspaceId).inserted { return ut.teamspaceId }
      return nil
    }
    guard !ids.isEmpty else { return [] }
    
    struct Indexed { let index: Int; let item: Teamspace }
    
    let fetched: [Indexed] = try await withThrowingTaskGroup(of: Indexed.self) { group in
      for (idx, id) in ids.enumerated() {
        group.addTask { @MainActor in
          let t: Teamspace = try await FirestoreManager.shared.get(id, from: .teamspace)
          return Indexed(index: idx, item: t)
        }
      }
      var acc: [Indexed] = []
      for try await v in group { acc.append(v) }
      return acc
    }
    return fetched.sorted { $0.index < $1.index }.map(\.item)
  }
  
  /// 현재 로그인 유저가 팀장(owner)인지 여부를 판별합니다.
  /// - 사용처:
  ///   - onAppear()
  func isTeamspaceOwner() -> Bool {
    self.currentTeamspace?.ownerId == FirebaseAuthManager.shared.userInfo?.userId ?? ""
  }
}
