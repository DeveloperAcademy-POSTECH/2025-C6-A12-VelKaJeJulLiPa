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


@Model
final class ProjectCache {
  @Attribute(.unique) var teamspaceId: String
  var updatedAt: Date
  var project: [Project]
  
  init(teamspaceId: String, updatedAt: Date, project: [Project]) {
    self.teamspaceId = teamspaceId
    self.updatedAt = updatedAt
    self.project = project
  }
}


@Model
final class TracksCache {
  @Attribute(.unique) var projectId: String
  var updatedAt: Date
  var tracks: [Tracks]
  
  init(projectId: String, updatedAt: Date, tracks: [Tracks]) {
    self.projectId = projectId
    self.updatedAt = updatedAt
    self.tracks = tracks
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
}


// MARK: - Teamspace Cache
extension CacheStore {
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
      context.insert(TeamspaceCache(userId: userId, updatedAt: userUpdatedAt, teamspace: teamspace))
      print("context 삽입 성공")
      
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


// MARK: - Project Cache
extension CacheStore {
  // 특정 사용자 updatedAt 불러오기
  func checkedProjectUpdatedAt(teamspaceId: String) throws -> String {
    let cacheData = FetchDescriptor<ProjectCache>(
      predicate: #Predicate { $0.teamspaceId == teamspaceId }
    )
    guard let updatedAt = try context.fetch(cacheData).first?.updatedAt.iso8601KST() else { return "" }
    
    return updatedAt
  }
  
  // 특정 팀 스페이스 캐시 불러오기
  func loadProjects(teamspaceId: String) throws -> [Project] {
    let fd = FetchDescriptor<ProjectCache>(
      predicate: #Predicate { $0.teamspaceId == teamspaceId }
    )
    return try context.fetch(fd).first?.project ?? []
  }
  
  // 전체 교체 저장(upsert)
  func replaceProjects(teamspaceId: String, teamspaceUpdatedAt: Date, project: [Project]) throws {
    let fd = FetchDescriptor<ProjectCache>(
      predicate: #Predicate { $0.teamspaceId == teamspaceId }
    )
    if let existing = try context.fetch(fd).first {
      existing.project = project
      existing.updatedAt = teamspaceUpdatedAt
    } else {
      do {
        context.insert(
          ProjectCache(
            teamspaceId: teamspaceId,
            updatedAt: teamspaceUpdatedAt,
            project: project
          )
        )
        print("context 삽입 성공")
      }
    }
    try context.save()
  }
  
  // 캐시 비우기
  func projectCacheClear(teamspaceId: String) throws {
    let fd = FetchDescriptor<ProjectCache>(predicate: #Predicate { $0.teamspaceId == teamspaceId })
    for item in try context.fetch(fd) { context.delete(item) }
    try context.save()
  }
}


// MARK: - Tracks Chache
extension CacheStore {
  // Tracks updatedAt 불러오기
  func checkedTracksUpdatedAt(projectId: String) throws -> String {
    let cacheData = FetchDescriptor<TracksCache>(
      predicate: #Predicate { $0.projectId == projectId }
    )
    guard let updatedAt = try context.fetch(cacheData).first?.updatedAt.iso8601KST() else { return "" }
    
    return updatedAt
  }
  
  // 특정 Tracks 캐시 불러오기
  func loadTracks(projectId: String) throws -> [Tracks] {
    let fd = FetchDescriptor<TracksCache>(
      predicate: #Predicate { $0.projectId == projectId }
    )
    return try context.fetch(fd).first?.tracks ?? []
  }
  
  // 전체 교체 저장(upsert)
  func replaceTracks(projectId: String, projectIdUpdatedAt: Date, tracks: [Tracks]) throws {
    let fd = FetchDescriptor<TracksCache>(
      predicate: #Predicate { $0.projectId == projectId }
    )
    if let existing = try context.fetch(fd).first {
      existing.tracks = tracks
      existing.updatedAt = projectIdUpdatedAt
    } else {
        context.insert(
          TracksCache(
            projectId: projectId,
            updatedAt: projectIdUpdatedAt,
            tracks: tracks
          )
        )
        print("context 삽입 성공")
    }
    try context.save()
  }
  
  // 캐시 비우기
  func tracksCacheClear(projectId: String) throws {
    let fd = FetchDescriptor<TracksCache>(predicate: #Predicate { $0.projectId == projectId })
    for item in try context.fetch(fd) { context.delete(item) }
    try context.save()
  }
}




struct CacheStoreKey: EnvironmentKey {
  static let defaultValue: CacheStore = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
      for: TeamspaceCache.self,
          ProjectCache.self,
          TracksCache.self,
      configurations: config
    )
    return CacheStore(container: container)
  }()
}

extension EnvironmentValues {
  var cacheStore: CacheStore {
    get { self[CacheStoreKey.self] }
    set { self[CacheStoreKey.self] = newValue }
  }
}
