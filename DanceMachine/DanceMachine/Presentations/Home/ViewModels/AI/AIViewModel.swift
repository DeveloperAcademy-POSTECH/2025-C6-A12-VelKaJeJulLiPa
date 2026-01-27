//
//  AIViewModel.swift
//  DanceMachine
//
//  Created by 조재훈 on 1/23/26.
//

import Foundation
import DancePoseAnalysis

@Observable
final class AIViewModel {
  var state: AIState = .idle
  var visionFeedback: VisionFeedback?
  var errorMsg: String?

  enum AIState {
    case idle        // 대기
    case extracting  // 영상 업로드 중
    case analyzing   // AI 분석 중
    case completed   // 완료
    case failed      // 실패
  }

  // 프리뷰 함수
  static func preview(_ state: AIState) -> AIViewModel {
    let vm = AIViewModel()
    vm.state = state

    switch state {
    case .completed: vm.visionFeedback = VisionFeedback.mockGood
    case .failed: vm.errorMsg = "포즈 감지에 실패했습니다."
    default: break
    }
    return vm
  }
}

// MARK: - 분석
extension AIViewModel {
  // Gemini 3 Vision 방식
  func startAnalysis(
    videoId: String,
    onComplete: @escaping (VisionFeedback) async -> Void
  ) async {
    self.state = .extracting

    do {
      // 1. 캐싱된 로컬 비디오 URL 가져오기
      print("🎬 Step 1: Getting cached video")
      guard let localURL = await VideoCacheManager.shared.getCachedVideoURL(for: videoId) else {
        throw AIError.videoNotCached
      }
      print("✅ Step 1: Got local video")

      // 2. GEMINI File API에 업로드
      print("📤 Step 2: Uploading to Gemini File API")
      let fileURI = try await GeminiFileManager.shared.uploadVideo(localURL)
      print("✅ Step 2: Upload complete")

      // 3. GEMINI 3 VISION으로 분석
      print("🤖 Step 3: Analyzing with Gemini 3 Vision")
      self.state = .analyzing
      let feedback = try await GeminiVisionEngine.shared.analyzeVideo(fileURI: fileURI)
      print("✅ Step 3: Analysis complete")
      print("📊 Overall score: \(feedback.overallScore)")
      print("⚠️ Critical errors: \(feedback.criticalErrors.count)")

      // 4. 결과 표시
      self.visionFeedback = feedback
      self.state = .completed

      // 5. 비동기 콜백
      await onComplete(feedback)

    } catch {
      print("❌ Analysis failed: \(error.localizedDescription)")
      self.errorMsg = error.localizedDescription
      self.state = .failed
    }
  }

  func reset() {
    self.state = .idle
    self.visionFeedback = nil
    self.errorMsg = nil
  }
}

enum AIError: LocalizedError {
  case invalidURL
  case videoNotCached

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "유효하지 않은 비디오 URL입니다."
    case .videoNotCached:
      return "비디오가 캐싱되지 않았습니다. 영상을 다시 재생해주세요."
    }
  }
}
