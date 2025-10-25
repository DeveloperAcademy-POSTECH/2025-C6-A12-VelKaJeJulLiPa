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
  
  init() {
    self.videoVM = VideoViewModel()
    self.feedbackVM = FeedbackViewModel()
    
  }
  
  // 팀 멤버 이름 유틸 함수
  func getTaggedUsers(for ids: [String]) -> [User] {
    teamMembers.filter { ids.contains($0.userId) }
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
// MARK: - 프리뷰 전용 목데이터
extension VideoDetailViewModel {
  static var preview: VideoDetailViewModel {
    let vm = VideoDetailViewModel()
    
    let members = [
      User(
        userId: "1",
        email: "",
        name: "카단",
        loginType: LoginType.apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      ),
      User(
        userId: "2",
        email: "",
        name: "진",
        loginType: LoginType.apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      ),
      User(
        userId: "3",
        email: "",
        name: "조재훈",
        loginType: LoginType.apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      )
    ]
    vm.teamMembers = members
    
    let feedback1 = Feedback(
      feedbackId: UUID(),
      videoId: "video1",
      authorId: members[0].name,
      content: "이 부분 춤 동작이 자연스러워요",
      taggedUserIds: [members[1].userId],
      startTime: 12.5,
      endTime: 15.5,
      createdAt: Date()
    )
    let feedback2 = Feedback(
      feedbackId: UUID(),
      videoId: "video1",
      authorId: members[2].name,
      content: "조명 때문에 일부 장면이 잘 안 보여요",
      taggedUserIds: [],
      startTime: 45.0,
      endTime: nil,
      createdAt: Date() + 100
    )
    vm.feedbackVM.feedbacks = [feedback1, feedback2]
    
    let reply1 = Reply(
      replyId: UUID().uuidString,
      feedbackId: feedback1.feedbackId.uuidString,
      authorId: members[1].name,
      content: "맞아요, 저도 그렇게 생각합니다",
      taggedUserIds: []
    )
    let reply2 = Reply(
      replyId: UUID().uuidString,
      feedbackId: feedback1.feedbackId.uuidString,
      authorId: members[2].name,
      content: "다만 마지막 동작은 조금 어색한 느낌",
      taggedUserIds: []
    )
    vm.feedbackVM.reply = [
      feedback1.feedbackId.uuidString: [reply1, reply2],
      feedback2.feedbackId.uuidString: []
    ]
    
    return vm
  }
  
  // 팀 멤버 이름 유틸 함수
  func getTaggedUsers(for ids: [String]) -> [User] {
    teamMembers.filter { ids.contains($0.userId) }
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
// MARK: - 프리뷰 전용 목데이터
extension VideoDetailViewModel {
  static var preview: VideoDetailViewModel {
    let vm = VideoDetailViewModel(videoURL: "https://example.com/video.mp4")
    
    let members = [
      User(
        userId: "1",
        email: "",
        name: "카단",
        loginType: LoginType.apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      ),
      User(
        userId: "2",
        email: "",
        name: "진",
        loginType: LoginType.apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      ),
      User(
        userId: "3",
        email: "",
        name: "조재훈",
        loginType: LoginType.apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      )
    ]
    vm.teamMembers = members
    
    let feedback1 = Feedback(
      feedbackId: UUID(),
      videoId: "video1",
      authorId: members[0].name,
      content: "이 부분 춤 동작이 자연스러워요",
      taggedUserIds: [members[1].userId],
      startTime: 12.5,
      endTime: 15.5,
      createdAt: Date()
    )
    let feedback2 = Feedback(
      feedbackId: UUID(),
      videoId: "video1",
      authorId: members[2].name,
      content: "조명 때문에 일부 장면이 잘 안 보여요",
      taggedUserIds: [],
      startTime: 45.0,
      endTime: nil,
      createdAt: Date() + 100
    )
    vm.feedbackVM.feedbacks = [feedback1, feedback2]
    
    let reply1 = Reply(
      replyId: UUID().uuidString,
      feedbackId: feedback1.feedbackId.uuidString,
      authorId: members[1].name,
      content: "맞아요, 저도 그렇게 생각합니다",
      taggedUserIds: []
    )
    let reply2 = Reply(
      replyId: UUID().uuidString,
      feedbackId: feedback1.feedbackId.uuidString,
      authorId: members[2].name,
      content: "다만 마지막 동작은 조금 어색한 느낌",
      taggedUserIds: []
    )
    vm.feedbackVM.reply = [
      feedback1.feedbackId.uuidString: [reply1, reply2],
      feedback2.feedbackId.uuidString: []
    ]
    
    return vm
  }
}
