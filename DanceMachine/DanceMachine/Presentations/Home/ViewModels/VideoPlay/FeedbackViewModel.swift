//
//  FeedbackViewModel.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/4/25.
//

import Foundation

@Observable
final class FeedbackViewModel {
  private let store = FirestoreManager.shared
  
  var isLoading: Bool = false
  var errorMsg: String? = nil
  
  var feedbacks: [Feedback] = []
  var reply: [String: [Reply]] = [:]
  var teamMembers: [User] = []
  
  // 구간 피드백 상태
  var isRecordingInterval: Bool = false
  var intervalStartTime: Double? = nil
  
  // MARK: 뷰 관련 로직
  // 구간 피드백 상태 제어
  func handleIntervalButtonType(currentTime: Double) -> Bool {
    if isRecordingInterval {
      return true
    } else {
      intervalStartTime = currentTime
      isRecordingInterval = true
      return false
    }
  }
}
// MARK: 피드백 관련
extension FeedbackViewModel {
  // videoId로 모든 피드백 조회
  func loadFeedbacks(for videoId: String) async throws {
    await MainActor.run {
      self.isLoading = true
      self.errorMsg = nil
    }
    
    let startTime = Date()
    
    await TaskTimeUtility.waitForMinimumLoadingTime(
      startTime: startTime
    )
    
    do {
      let fetchedFeedback: [Feedback] = try await store.fetchAll(
        videoId,
        from: .feedback,
        where: "video_id"
      )
      
      await MainActor.run {
        self.feedbacks = fetchedFeedback.sorted {
          ($0.createdAt ?? Date()) > ($1.createdAt ?? Date())
        }
        self.isLoading = false
      }
      
      for feedback in fetchedFeedback {
        await loadReply(for: feedback.feedbackId.uuidString)
      }
      
    } catch { // TODO: 에러처리
      await MainActor.run {
        self.isLoading = false
        self.errorMsg = "피드백을 불러오는데 실패했습니다!"
      }
      print("피드백 조회 실패: \(error)")
    }
  }
  // 시점 피드백 생성
  func createPointFeedback(
    videoId: String,
    authorId: String,
    content: String,
    taggedUserIds: [String],
    atTime: Double
  ) async {
    await MainActor.run {
      self.errorMsg = nil
    }
    
    do {
      let feedback = Feedback(
        feedbackId: UUID(),
        videoId: videoId,
        authorId: authorId,
        content: content,
        taggedUserIds: taggedUserIds,
        startTime: atTime,
        endTime: nil,
        createdAt: Date(),
        teamspaceId: FirebaseAuthManager.shared.currentTeamspace?.teamspaceId.uuidString ?? "",
      )
      try await store.create(feedback)

      await MainActor.run {
        self.feedbacks.insert(feedback, at: 0)
      }
    } catch { // TODO: 에러처리
      await MainActor.run {
        self.errorMsg = "피드백 작성에 실패했습니다!"
      }
      print("피드백 생성 실패: \(error)")
    }
  }
  // 구간 피드백 생성
  func createIntervalFeedback(
    videoId: String,
    authorId: String,
    content: String,
    taggedUserIds: [String],
    startTime: Double,
    endTime: Double
  ) async {
    await MainActor.run {
      self.errorMsg = nil
    }
    
    do {
      let feedback = Feedback(
        feedbackId: UUID(),
        videoId: videoId,
        authorId: authorId,
        content: content,
        taggedUserIds: taggedUserIds,
        startTime: startTime,
        endTime: endTime,
        createdAt: Date(),
        teamspaceId: FirebaseAuthManager.shared.currentTeamspace?.teamspaceId.uuidString ?? "",
      )
      try await store.create(feedback)

      await MainActor.run {
        self.feedbacks.insert(feedback, at: 0)

        self.isRecordingInterval = false
        self.intervalStartTime = nil
      }
    } catch {
      await MainActor.run {
        self.errorMsg = "피드백 작성에 실패했습니다!"
      }
      print("구간 피드백 생성 실패: \(error)")
    }
  }
  // TODO: 피드백 삭제
  func deleteFeedback(_ feedback: Feedback) async {
    await MainActor.run {
      self.isLoading = true
      self.errorMsg = nil
    }
    
    do {
      let feedbackId = feedback.feedbackId.uuidString
      
      try await withThrowingTaskGroup(of: Void.self) { g in
        if let replies = self.reply[feedbackId] {
          for reply in replies {
            g.addTask {
              try await self.store.deleteFromSubcollection(
                under: .feedback,
                parentId: feedbackId,
                subCollection: .reply,
                target: reply.replyId
              )
            }
          }
        }
        g.addTask {
          try await self.store.delete(
            collectionType: .feedback,
            documentID: feedbackId
          )
        }
        try await g.waitForAll()
      }
      
      await MainActor.run {
        self.feedbacks.removeAll { $0.feedbackId == feedback.feedbackId }
        self.reply.removeValue(forKey: feedback.feedbackId.uuidString)
        self.isLoading = false
      }
    } catch { // TODO: 에러 처리
      print("피드백 삭제 실패: \(error)")
      self.errorMsg = "피드백 삭제에 실패했습니다."
    }
  }
}
// MARK: 댓글 관련
extension FeedbackViewModel {
  // 피드백의 댓글 조회
  func loadReply(for feedbackId: String) async {
    do {
      let fetchedReply: [Reply] = try await store.fetchAllFromSubcollection(
        under: .feedback,
        parentId: feedbackId,
        subCollection: .reply,
        orderBy: "created_at",
        descending: false
      )
      
      await MainActor.run {
        self.reply[feedbackId] = fetchedReply
      }
      
    } catch { // TODO: 에러처리
      print("댓글 조회 실패: \(error)")
    }
  }
  // 댓글 작성
  func addReply(
    to feedbackId: String,
    authorId: String,
    content: String,
    taggedUserIds: [String]
  ) async {
    do {
      let reply = Reply(
        replyId: UUID().uuidString,
        feedbackId: feedbackId,
        authorId: authorId,
        content: content,
        taggedUserIds: taggedUserIds
      )
      
      try await store.createToSubcollection(
        reply,
        under: .feedback,
        parentId: feedbackId,
        subCollection: .reply,
        strategy: .create
      )
      
      await MainActor.run {
        if self.reply[feedbackId] != nil {
          self.reply[feedbackId]?.append(reply)
        } else {
          self.reply[feedbackId] = [reply]
        }
      }
    } catch { // TODO: 에러 처리
      print("댓글 작성 실패: \(error)")
    }
  }
  
  func deleteReply(replyId: String, from feedbackId: String) async {
    await MainActor.run {
      self.isLoading = true
      self.errorMsg = nil
    }
    
    do {
      try await store.deleteFromSubcollection(
        under: .feedback,
        parentId: feedbackId,
        subCollection: .reply,
        target: replyId
      )
      
      await MainActor.run {
        if var replies = self.reply[feedbackId] {
          replies.removeAll { $0.replyId == replyId }
          self.reply[feedbackId] = replies
        }
        self.isLoading = false
      }
    } catch {
      await MainActor.run {
        self.isLoading = false
        self.errorMsg = "댓글 삭제에 실패했습니다."
      }
      print("댓글 삭제 실패: \(error)")
    }
  }
}
