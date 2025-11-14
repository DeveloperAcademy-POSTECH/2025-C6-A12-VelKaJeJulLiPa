//
//  Test.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/14/25.
//

import SwiftUI
import SwiftData

@Model
final class TeamspaceCache {
  @Attribute(.unique) var userId: String
  var updatedAt: Date
  var teamspace: [Teamspace]
  
  init(userId: String, updatedAt: Date, teamspace: [Teamspace]) {
    self.userId = userId
    self.updatedAt = updatedAt
    self.teamspace = teamspace
  }
}


@MainActor
final class CacheStore {
  let container: ModelContainer
  let context: ModelContext
  
  init(container: ModelContainer) {
    self.container = container
    self.context = ModelContext(container)
  }
  
  // 특정 사용자 updatedAt 불러오기
  func checkedUpdatedAt(userId: String) throws -> String {
    let cacheData = FetchDescriptor<TeamspaceCache>(
      predicate: #Predicate { $0.userId == userId }
    )
    
    guard let updatedAt = try context.fetch(cacheData).first?.updatedAt.iso8601KST() else { return "" }
    
    return updatedAt
  }
  
  // 특정 사용자 캐시 불러오기
  func loadTeamspaces(userId: String) throws -> [Teamspace] {
    let fd = FetchDescriptor<TeamspaceCache>(
      predicate: #Predicate { $0.userId == userId }
    )
    return try context.fetch(fd).first?.teamspace ?? []
  }
  
  // 전체 교체 저장(upsert)
  func replaceTeamspaces(userId: String, userUpdatedAt: Date, teamspace: [Teamspace]) throws {
    let fd = FetchDescriptor<TeamspaceCache>(
      predicate: #Predicate { $0.userId == userId }
    )
    if let existing = try context.fetch(fd).first {
      existing.teamspace = teamspace
      existing.updatedAt = userUpdatedAt
    } else {
      do {
        context.insert(TeamspaceCache(userId: userId, updatedAt: userUpdatedAt, teamspace: teamspace))
        print("context 삽입 성공")
      } catch {
        print("insert error: \(error.localizedDescription)")
      }
    }
    try context.save()
  }
  
  // 캐시 비우기(선택사항)
  func clear(for userId: String) throws {
    let fd = FetchDescriptor<TeamspaceCache>(predicate: #Predicate { $0.userId == userId })
    for item in try context.fetch(fd) { context.delete(item) }
    try context.save()
  }
}




struct CacheStoreKey: EnvironmentKey {
  static let defaultValue: CacheStore = {
    // 미리보기나 안전용으로 메모리 컨테이너
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TeamspaceCache.self, configurations: config)
    return CacheStore(container: container)
  }()
}

extension EnvironmentValues {
  var cacheStore: CacheStore {
    get { self[CacheStoreKey.self] }
    set { self[CacheStoreKey.self] = newValue }
  }
}
