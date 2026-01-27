//
//  VideoDetailViewModel.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/4/25.
//

import Foundation
import UIKit
import DancePoseAnalysis

@Observable
final class VideoDetailViewModel {
  private let store = FirestoreManager.shared
  
  var teamMembers: [User] = []
  
  var videoVM: VideoViewModel
  var feedbackVM: FeedbackViewModel
  var aiVM: AIViewModel
  
  var isLoading: Bool = false
  var showMemberError: Bool = false
  var errorMsg: String = ""
  
  // Feedback패널에서 사용되는 상태
  var showAIPanel: Bool = false
  var aiAnalysis: AIAnalysis?
  
  init() {
    self.videoVM = VideoViewModel()
    self.feedbackVM = FeedbackViewModel()
    self.aiVM = AIViewModel()
  }
  
  // 팀 멤버 이름 유틸 함수 (태그 관련)
  func getTaggedUsers(for ids: [String]) -> [User] {
    teamMembers.filter { ids.contains($0.userId) }
  }
  // 작성자 이름
  func getAuthorUser(for authorId: String) -> User? {
    teamMembers.first { $0.userId == authorId }
  }
  
  func loadAllData(
    videoId: String,
    videoURL: String,
    teamspaceId: String
  ) async {
    if ProcessInfo.isRunningInPreviews { return } // 프리뷰 전용

    await MainActor.run {
      self.isLoading = true
    }

    // 각각 독립적으로 에러 처리
    await withTaskGroup(of: Void.self) { g in
      // 비디오 로드 (VideoViewModel 내부에서 에러 처리)
      g.addTask {
        await self.videoVM.setupPlayer(from: videoURL, videoId: videoId)
      }

      // 팀 멤버 로드 (내부에서 에러 처리)
      g.addTask {
        await self.loadTeamMembers(teamspaceId: teamspaceId)
      }

      // 피드백 로드 (FeedbackViewModel 내부에서 에러 처리)
      g.addTask {
        await self.feedbackVM.loadFeedbacks(for: videoId)
      }
      
      // AI 분석 로드
      g.addTask {
        await self.loadAIAnalysis(videoId: videoId)
      }

      await g.waitForAll()
    }

    await MainActor.run {
      self.isLoading = false
    }
  }
}
// MARK: 팀 스페이스 관련
extension VideoDetailViewModel {
  // 팀 스페이스 멤버 조회
  func loadTeamMembers(teamspaceId: String) async {
    do {

      let members = try await self.fetchMember(teamspaceId: teamspaceId)

      var users: [User] = []
      // 탈퇴한 유저는 스킵하고 존재하는 유저만 추가
      for member in members {
        do {
          let user: User = try await store.get(
            member.userId,
            from: .users
          )
          users.append(user)
        } catch {
          // 유저가 존재하지 않으면 (탈퇴한 경우) 스킵하고 계속 진행
          print("⚠️ 유저를 찾을 수 없습니다 (탈퇴한 유저일 수 있음): \(member.userId)")
          continue
        }
      }
      print("조회된 유저 수: \(users.count)")
      await MainActor.run {
        self.teamMembers = users
        self.errorMsg = ""
      }
    } catch let error as MemberError {
      await MainActor.run {
        self.showMemberError = true
        self.errorMsg = error.userMsg
      }
    } catch {
      await MainActor.run {
        self.showMemberError = true
        self.errorMsg = "알 수 없는 에러"
      }
    }
  }
  
  private func fetchMember(teamspaceId: String) async throws -> [Members] {
    do {
      let m: [Members] = try await store.fetchAllFromSubcollection(
        under: .teamspace,
        parentId: teamspaceId,
        subCollection: .members
      )
      return m
    } catch {
      throw MemberError.fetchFailed
    }
  }
  // 멘션 검색 기능
  func searchMembers(query: String) -> [User] {
    guard !query.isEmpty else { return teamMembers }
    return teamMembers.filter { $0.name.lowercased().contains(query.lowercased()) }
  }
}
// MARK: - AI 관련
extension VideoDetailViewModel {
  // AI 분석 로드
  func loadAIAnalysis(videoId: String) async {
    print("🔍 [1] loadAIAnalysis 시작 - videoId: \(videoId)")

    // guard 제거!

    do {
      print("🔍 [2] Firebase 쿼리 시작...")
      let analysis: [AIAnalysis] = try await FirestoreManager.shared.fetchAll(
        videoId,
        from: .aiAnalysis,
        where: "video_id"
      )

      print("🔍 [3] 쿼리 완료 - 결과: \(analysis.count)개")

      if let first = analysis.first {
        print("🔍 [4] 분석 데이터 발견!")
        await MainActor.run {
          self.aiAnalysis = first
          self.aiVM.visionFeedback = first.feedback
          self.aiVM.state = .completed
          print("✅ AI 분석 로드 완료")
        }
      } else {
        print("ℹ️ 분석 데이터 없음")
      }
    } catch {
      print("❌ 로드 실패: \(error)")
    }
  }


  
  // AI 분석 저장
  func saveAIAnalysis(
    _ visionFeedback: VisionFeedback,
    videoId: String
  ) async {
    let analysis = AIAnalysis(
      feedback: visionFeedback,
      videoId: videoId
    )

    do {
      try await FirestoreManager.shared.create(analysis)
      self.aiAnalysis = analysis
      print("✅ AI 분석 저장 완료 - Score: \(visionFeedback.overallScore)")
    } catch {
      // TODO: 에러처리
      print("❌ AI 분석 저장 실패: \(error)")
    }
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
      createdAt: Date(),
      teamspaceId: FirebaseAuthManager.shared.currentTeamspace?.teamspaceId.uuidString ?? "",
    )
    let feedback2 = Feedback(
      feedbackId: UUID(),
      videoId: "video1",
      authorId: members[2].name,
      content: "조명 때문에 일부 장면이 잘 안 보여요",
      taggedUserIds: [],
      startTime: 45.0,
      endTime: nil,
      createdAt: Date() + 100,
      teamspaceId: FirebaseAuthManager.shared.currentTeamspace?.teamspaceId.uuidString ?? "",
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
