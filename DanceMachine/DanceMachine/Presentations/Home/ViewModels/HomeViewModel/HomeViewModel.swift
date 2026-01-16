//
//  HomeViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import Foundation
import FirebaseAuth
import SwiftUI
import UserNotifications



/// 홈 화면의 뷰모델로, 팀스페이스 / 유저 / 알림 관련 상태와 로직을 관리합니다.
@Observable
final class HomeViewModel {
  
  var state = CurrentTeamspaceState()
  
  
  // 현재 선택된 팀스페이스 (FirebaseAuthManager의 currentTeamspace와 연동)
  var currentTeamspace: Teamspace? {
    FirebaseAuthManager.shared.currentTeamspace
  }
  
  // 현재 접속한 유저 정보 (get)
  var currentUserId: String? { FirebaseAuthManager.shared.userInfo?.userId }
  
  /// 유저가 속한 팀스페이스 목록 (읽기 전용)
  private(set) var userTeamspaces: [UserTeamspace] = []
  
  
  /// 최근 접속 팀 스페이스 아이디 불러오기 (AppStorage)
  @ObservationIgnored
  @AppStorage(AppStorageKey.lastAccessedTeamspaceId.rawValue)
  private(set) var lastAccessedTeamspaceId: String = ""
  
  
  @ObservationIgnored
  private(set) var cacheStore: CacheStore?
  
  
  init(cacheStore: CacheStore? = nil) {
    self.cacheStore = cacheStore
  }
  
  /// cacheData 셋팅
  func setCacheStore(_ cache: CacheStore) {
    self.cacheStore = cache
  }
  
  private var cache: CacheStore {
    guard let cacheStore else {
      fatalError("CacheStore not injected. Call setCacheStore(_:) first.")
    }
    return cacheStore
  }
  
  /// 홈뷰가 시작될 때 실행되는 메서드입니다.
  /// 팀스페이스 선택/캐싱까지만 처리하고, 프로젝트 로딩은 ProjectViewModel에서 처리한다는 전제.
  func onAppear() async {
    
    self.state.isLoading = true
    
    defer {
      self.state.isLoading = false
    }
    
    do {
      // 1. 현재 로그인 유저 정보 로드
      try await loadUserInfo()
      
      guard let user = FirebaseAuthManager.shared.userInfo else {
        print("🙅🏻‍♂️유저 오류")
        return
      }
      print("🙆🏻‍♂️현재 로그인 유저: \(user.name), \(user.id)")
      
      // 2. 유저가 속한 팀스페이스 목록 로드
      let userTeamspaces: [UserTeamspace] = await loadUserTeamspace()
      
      // 팀스페이스가 하나도 없으면 초기화 후 종료
      guard !userTeamspaces.isEmpty else {
        self.state.teamspaceState = .empty
        print("🙅🏻‍♂️유저의팀 스페이스가 존재하지 않음.(X)")
        return
      }
      
      // 3. 최근 접속 팀스페이스가 존재하는지 여부 (AppStoreage 체크)
      let hasLastAccessedTeamspace =
      !lastAccessedTeamspaceId.isEmpty &&
      userTeamspaces.contains { $0.teamspaceId == lastAccessedTeamspaceId }
      
      
      // 4. 최근 접속 팀 스페이스가 있으면, 해당 팀 스페이스의 정보를 로딩 후, return
      if hasLastAccessedTeamspace {
        FirebaseAuthManager.shared.currentTeamspace = try await self.loadTeamspace(documentId: lastAccessedTeamspaceId)
        self.state.teamspaceState = .nonEmpty
        print("📕 유저의팀 스페이스 정보를 AppStoreage에서 불러옵니다.")
        return
      }
      // 5. 최근 접속 팀 스페이스가 없다면, 유저 팀 스페이스에 존재하는 첫 번째 팀 스페이스로 팀 스페이스 로드
      else {
        guard let userTeamspaceId = userTeamspaces.first?.teamspaceId else { print("🙅🏻‍♂️유저의팀 스페이스가 존재하지 않음.(X)"); return }
        
        let teamspace = try await loadTeamspace(documentId: userTeamspaceId)
        FirebaseAuthManager.shared.currentTeamspace = teamspace
        state.teamspaceState = .nonEmpty
      }
      
      // TODO: 캐시 매니저 넣어야 함.
      
      
      //        if let first = self.currentTeamspace.list.first,
      //           state.currentTeamspace == nil {
      //
      //          let hasLast = !lastAccessedTeamspaceId.isEmpty &&
      //          userTeamspaces.contains { $0.teamspaceId == lastAccessedTeamspaceId }
      //
      //          if hasLast {
      //            // 마지막 팀스페이스가 실제로 존재하면 그걸 선택, 아니면 첫 번째로 fallback
      //            if let lastAccessedTeamspace: Teamspace = try? await FirestoreManager.shared.get(
      //              lastAccessedTeamspaceId,
      //              from: .teamspace
      //            ) {
      //              FirebaseAuthManager.shared.currentTeamspace = lastAccessedTeamspace
      //            } else {
      //              FirebaseAuthManager.shared.currentTeamspace = first
      //            }
      //          } else {
      //            // AppStorage에 저장된 값이 없으면 그냥 첫 번째 팀스페이스로 설정
      //            FirebaseAuthManager.shared.currentTeamspace = first
      //
      //            // 이때 팀스페이스 목록을 캐시에 저장
      //            if let updatedAt = user.updatedAt {
      //              try cache.replaceTeamspaces(
      //                userId: FirebaseAuthManager.shared.userInfo?.userId ?? "",
      //                userUpdatedAt: updatedAt,
      //                teamspace: self.teamspace.list
      //              )
      //            }
      //          }
      //        }
      
      // 프로젝트 로딩/캐싱은 이제 ProjectViewModel 쪽에서 수행 (여기서는 건드리지 않음)
      
    } catch {
      print("homeViewOnnAppear error: \(error.localizedDescription)")
    }
  }
}

//// MARK: - Private Method
extension HomeViewModel {
  
  /// 유저 정보를 FirebaseAuthManager를 통해 비동기적으로 가져옵니다.
  private func loadUserInfo() async throws {
    do {
      print("1️⃣fetchUserInfo() 실행")
      try await FirebaseAuthManager.shared.fetchUserInfo(for: FirebaseAuthManager.shared.user?.uid ?? "")
    } catch {
      print("fetchUserInfo() 오류: \(error.localizedDescription)")
    }
  }
  
  /// 유저가 속한 팀스페이스 목록을 viewModel userTeamspaces 속성에 할당합니다.
  private func loadUserTeamspace() async -> [UserTeamspace] {
    do {
      print("2️⃣fetchUserTeamspace() 실행")
      return try await FirestoreManager.shared.fetchAllFromSubcollection(
        under: .users,
        parentId: FirebaseAuthManager.shared.userInfo?.userId ?? "", // FIXME: - 살펴보기
        subCollection: .userTeamspace
      )
    } catch {
      print("fetchUserTeamspace() 오류: \(error.localizedDescription)")
      return []
    }
  }
  
  
  /// 팀 스페이스 리스트 패치를 진행하는 메서드 입니다.
  private func loadTeamspace(documentId: String) async throws -> Teamspace {
    // AppStorage에 저장된 마지막 팀스페이스를 Firestore에서 가져와 currentTeamspace로 설정
    return try await FirestoreManager.shared.get(
      documentId,
      from: .teamspace
    )
  }
  
  
  
  
  
  /// 유저 + 유저팀스페이스 정보를 기반으로
  /// 1) 캐시가 최신이면 SwiftData에서 팀스페이스 로드
  /// 2) 아니면 Firestore에서 다시 로드 후 캐시 갱신
  //  private func loadTeamspacesUsingCache(
  //    user: User,
  //    userTeamspaces: [UserTeamspace]
  //  ) async throws {
  //    let userId = user.userId
  //    let cachedStamp = try cache.checkedUpdatedAt(userId: userId)
  //    let remoteStamp = user.updatedAt?.iso8601KST()
  //
  //    if cachedStamp == remoteStamp {  // 캐시에서 로드
  //      let teamspace = try cache.loadTeamspaces(userId: userId)
  //      self.teamspace.list = teamspace
  //      self.teamspace.state = teamspace.isEmpty ? .empty : .nonEmpty
  //      print("🔥🔥🔥팀 스페이스 캐싱 불러오기 성공🔥🔥🔥")
  //    } else {
  //      // 네트워크에서 새로 로드하는 부분은 필요해지면 구현
  //      // (프로젝트/트랙 쪽은 여기서 더 이상 건드리지 않음)
  //    }
  //  }
}



// MARK: - 알림 기능 설정
extension HomeViewModel {
  func setupNotificationAuthorizationIfNeeded() async {
    let center = UNUserNotificationCenter.current()
    let settings = await center.notificationSettings()
    
    switch settings.authorizationStatus {
    case .notDetermined:
      requestNotificationAuthorization()
    case .denied:
      print("User has denied notifications")
    case .authorized, .provisional, .ephemeral:
      print("Notifications already authorized.")
      // 앱 재설치 시에도 APNs 토큰을 다시 등록해야 함
      await MainActor.run {
        print("🔔 registerForRemoteNotifications() 호출 시작")
        UIApplication.shared.registerForRemoteNotifications()
        print("🔔 registerForRemoteNotifications() 호출 완료")
      }
    @unknown default:
      print("Unknown notification authorization status.")
    }
  }
  //
  //  /// 푸시 알림 권한을 사용자에게 물어봄 + 권한 승인하면 APNs에 등록
  func requestNotificationAuthorization() {
    let center = UNUserNotificationCenter.current()
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    center.requestAuthorization(options: authOptions) { granted, error in
      print("Notification permission state: \(granted)")
      if granted {
        Task { @MainActor in
          print("🔔 registerForRemoteNotifications() 호출 시작 (권한 승인 후)")
          UIApplication.shared.registerForRemoteNotifications()
          print("🔔 registerForRemoteNotifications() 호출 완료 (권한 승인 후)")
        }
      }
      if let error = error {
        print("Error requesting notifications: \(error)")
      }
    }
  }
}
