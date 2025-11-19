//
//  FeedbackViewModel.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/4/25.
//

import Foundation
import UIKit

@Observable
final class FeedbackViewModel {
  private let store = FirestoreManager.shared
  private let storage = FireStorageManager.shared
  
  var isUploading: Bool = false
  
  var isLoading: Bool = false
  var errorMsg: String? = nil
  var showErrorView: Bool = false
  
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
// MARK: 서버 관련
extension FeedbackViewModel {
  // videoId로 모든 피드백 조회
  func loadFeedbacks(for videoId: String) async {
    await MainActor.run {
      self.isLoading = true
      self.errorMsg = nil
      self.showErrorView = false
    }
    
    let startTime = Date()
    
    await TaskTimeUtility.waitForMinimumLoadingTime(
      startTime: startTime
    )
    
    
    do {
      
      let fetchedFeedback = try await self.fecthFeedback(videoId: videoId)
      
      for feedback in fetchedFeedback {
        try await loadReply(for: feedback.feedbackId.uuidString)
      }
      
      await MainActor.run {
        self.isLoading = false
        self.showErrorView = false
      }
      
    } catch let error as FeedbackError {
      await MainActor.run {
        self.isLoading = false
        self.errorMsg = error.userMsg
        self.showErrorView = true
      }
      print(error.debugMsg)
    } catch {
      await MainActor.run {
        self.isLoading = false
        self.errorMsg = "알 수 없는 오류입니다.\n잠시 후에 다시 시도해주세요."
        self.showErrorView = true
      }
      print("알 수 없는 오류로 피드백 불러오기 실패")
    }
  }
  
  private func fecthFeedback(videoId: String) async throws -> [Feedback] {
    do {
      let f: [Feedback] = try await store.fetchAll(
        videoId,
        from: .feedback,
        where: "video_id"
      )
      
      await MainActor.run {
        self.feedbacks = f.sorted {
          ($0.createdAt ?? Date()) > ($1.createdAt ?? Date())
        }
      }
     return f
      
    } catch {
      throw FeedbackError.fetchFeedbackFailed
    }
  }
}

// MARK: - 피드백 CRUD
extension FeedbackViewModel {
  // 시점 피드백 생성 -
  func createPointFeedback(
    videoId: String,
    authorId: String,
    content: String,
    taggedUserIds: [String],
    atTime: Double,
    image: UIImage?
  ) async {
    await MainActor.run {
      self.isUploading = true
      self.errorMsg = nil
    }
    
    do {
      // 1) 이미지가 있을 때만 업로드
      var imageURL: String? = nil
      
      if let image,
         let imageData = image.pngData() {
        
        let path = try await storage.uploadStorage(
          data: imageData,
          type: .feedbackImage(UUID().uuidString)
        )
        imageURL = try await FireStorageManager.shared.getDownloadURL(for: path)
      } else {
        print("이미지 없음 또는 PNG 변환 실패 – 이미지 없이 피드백만 저장") // FIXME: - 적절한 에러 처리
      }
      
      // 2) 피드백 문서 생성 (이미지 유무 상관없이)
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
        imageURL: imageURL
      )
      
      try await store.create(feedback)
      
      await MainActor.run {
        self.feedbacks.insert(feedback, at: 0)
        self.isUploading = false
      }
      
    } catch {
      await MainActor.run {
        self.errorMsg = "피드백 작성에 실패했습니다!"
      }
      print("피드백 생성 실패: \(error)")
    }
  }
  // 구간 피드백 생성 -
  func createIntervalFeedback(
    videoId: String,
    authorId: String,
    content: String,
    taggedUserIds: [String],
    startTime: Double,
    endTime: Double,
    image: UIImage?
  ) async {
    await MainActor.run {
      self.isUploading = true
      self.errorMsg = nil
    }
    
    do {
      // 1) 이미지가 있을 때만 업로드
      var imageURL: String? = nil
      
      if let image,
         let imageData = image.pngData() {
        
        let path = try await storage.uploadStorage(
          data: imageData,
          type: .feedbackImage(UUID().uuidString)
        )
        imageURL = try await FireStorageManager.shared.getDownloadURL(for: path)
      } else {
        print("이미지 없음 또는 PNG 변환 실패 – 이미지 없이 피드백만 저장") // FIXME: - 적절한 에러 처리
      }
      
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
        imageURL: imageURL
      )
      try await store.create(feedback)
      
      await MainActor.run {
        self.feedbacks.insert(feedback, at: 0)
        
        self.isRecordingInterval = false
        self.intervalStartTime = nil
        self.isUploading = false
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
  func loadReply(for feedbackId: String) async throws {
    throw FeedbackError.fetchReplyFailed
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
      
    } catch {
      throw FeedbackError.fetchReplyFailed
      self.showErrorView = true
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
