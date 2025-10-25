//
//  VideoDetailViewModel.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/4/25.
//

import Foundation

@Observable
final class VideoDetailViewModel {
  private let store = FirestoreManager.shared
  
  var teamMembers: [User] = []
  
  var videoVM: VideoViewModel
  var feedbackVM: FeedbackViewModel
  
  init(videoURL: String) {
    self.videoVM = VideoViewModel()
    self.feedbackVM = FeedbackViewModel()
    
    videoVM.setupPlayer(from: videoURL)
  }
}
// MARK: 팀 스페이스 관련
extension VideoDetailViewModel {
  // 팀 스페이스 멤버 조회
  func loadTeamMemvers(teamspaceId: String) async {
    do {
      let members: [Members] = try await store.fetchAllFromSubcollection(
        under: .teamspace,
        parentId: teamspaceId,
        subCollection: .members
      )
      
      var users: [User] = []
      for member in members {
        let user: [User] = try await store.get(
          member.userId,
          from: .users
        )
        users.append(contentsOf: user)
      }
      await MainActor.run {
        self.teamMembers = users
      }
    } catch { // TODO: 에러 처리
      print("팀 멤버 조회 실패: \(error)")
    }
  }
  // 멘션 검색 기능
  func searchMembers(query: String) -> [User] {
    guard !query.isEmpty else { return teamMembers }
    return teamMembers.filter { $0.name.lowercased().contains(query.lowercased()) }
  }
}
