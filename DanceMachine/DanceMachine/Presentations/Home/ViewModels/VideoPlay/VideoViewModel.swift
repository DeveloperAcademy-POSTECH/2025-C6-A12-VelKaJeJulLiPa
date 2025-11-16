//
//  VideoViewModel.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/4/25.
//

import Foundation
import SwiftUI
import AVKit

@Observable
final class VideoViewModel {
  private let cacheManager = VideoCacheManager.shared
  
  var player: AVPlayer? = AVPlayer()
  
  var isPlaying: Bool = false
  var showControls: Bool = false

  // 영상 관련
  var timeObserver: Any?
  var currentTime: Double = .zero // 현재 영상 길이
  var duration: Double = .zero // 전체 영상 길이
  var hasFinished: Bool = false // 동영상 끝났는지 여부
  
  // 탭 제스처 관련
  var lastTapTime: Date = Date()
  var tapCount: Int = .zero
  var autoHideControlsTask: Task<Void, Never>?
  var singleTapTask: Task<Void, Never>?
  private let doubleTap: TimeInterval = 0.2

  // 더블탭 애니메이션 관련
  var showLeftSeekIndicator: Bool = false
  var showRightSeekIndicator: Bool = false
  var leftSeekCount: Int = 0
  var rightSeekCount: Int = 0
  var seekIndicatorTask: Task<Void, Never>?
  
  var loadingProgress: Double = 0.0
  var isLoading: Bool = false
  var isDownloading: Bool = false
  
  // 배속 변수
  var playbackSpeed: Float = 1.0
  
  var notiFalseAlert: Bool = false
}

// MARK: - 영상관련 메서드
extension VideoViewModel {
  // MARK: 동영상 Player 설정 (AVFoundation)
  func setupPlayer(from videoURL: String, videoId: String) async throws {
    await MainActor.run {
      self.isLoading = true
      self.loadingProgress = 0.0
    }
    
    /// 알림 버그 수정
    guard let _: Video = try await FirestoreManager.shared.get(videoId, from: .video) else {
      print("비디오 정보 없음")
      self.notiFalseAlert = true
      return
    }
    
    do {
      if let cachedURL = await cacheManager.getCachedVideoURL(for: videoId) {
        print("캐시에서 비디오 로드0")
        await setupPlayerWithURL(cachedURL)
        await MainActor.run {
          self.isLoading = false
        }
        return
      }
      
      print("네트워크에서 다운로드 시작")
      await MainActor.run {
        self.isDownloading = true
      }
      let cachedURL = try await cacheManager.downloadAndCacheVideo(
        from: videoURL,
        videoId: videoId) { [weak self] progress in
          Task { @MainActor in
            self?.loadingProgress = progress
          }
        }
      
      await setupPlayerWithURL(cachedURL)
      
      await MainActor.run {
        self.isLoading = false
        self.isDownloading = false
      }
      
    } catch {
      print("비디오 로드 실패: \(error)")
      throw error
    }
  }
  // MARK: URL로 플레이어 설정
  private func setupPlayerWithURL(_ url: URL) async {
    let playerItem = AVPlayerItem(url: url)
    
    await MainActor.run {
      self.player = AVPlayer(playerItem: playerItem)
    }
    
    await MainActor.run {
      timeObserver = player?.addPeriodicTimeObserver(
        forInterval: CMTime(seconds: 0.1, preferredTimescale: 6000),
        queue: DispatchQueue.main,
        using: { [weak self] time in
          guard let self = self else { return }
          self.currentTime = time.seconds

          // 동영상이 끝났는지 확인 (duration의 0.1초 이내)
          if self.duration > 0 && abs(self.currentTime - self.duration) < 0.1 {
            self.hasFinished = true
            self.isPlaying = false
            self.showControls = true // 컨트롤 자동으로 표시
            self.autoHideControlsTask?.cancel() // 자동 숨김 타이머 취소
          }
        }
      )
    }
    
    if let asset = playerItem.asset as? AVURLAsset {
      do {
        let duration = try await asset.load(.duration)
        await MainActor.run {
          self.duration = duration.seconds
          print("비디오 길이: \(duration)")
        }
      } catch {
        print("전체 영상 길이 가져오기 실패")
      }
    }
  }
  // MARK: Player 해제
  func cleanPlayer() {
    if let p = player,
       let t = timeObserver {
      p.removeTimeObserver(t)
      self.timeObserver = nil
    }
  }
  // MARK: 시간 이동 메서드
  func seekToTime(to time: Double) {
    guard let p = player else { return }
    
    let t = max(0, min(time, duration))
    let cmT = CMTime(
      seconds: t,
      preferredTimescale: 600
    )
    
    p.seek(to: cmT)
    currentTime = t
  }
  // MARK: 배속 조절
  func setPlaybackSpeed(_ speed: Float) {
    self.playbackSpeed = speed
    self.player?.rate = speed
    
    if !isPlaying {
      self.player?.rate = 0
    }
  }
  // MARK: 재생 정지 메서드
  func togglePlayPause() {
    if isPlaying {
      player?.pause()
      // 일시정지 시 자동 숨김 타이머 취소
      autoHideControlsTask?.cancel()
      isPlaying = false
    } else {
      // 동영상이 끝났으면 처음부터 재생
      if hasFinished {
        seekToTime(to: 0)
        hasFinished = false
      }

      player?.play()
      player?.rate = playbackSpeed
      isPlaying = true
      // 재생 시작하면 컨트롤 자동 숨김 타이머 시작
      startAutoHideControls()
    }
  }

  // MARK: 컨트롤 자동 숨김 타이머
  func startAutoHideControls() {
    // 기존 타이머 취소
    autoHideControlsTask?.cancel()

    // 재생 중이고 컨트롤이 보이는 경우에만 타이머 시작
    guard isPlaying, showControls else { return }

    autoHideControlsTask = Task {
      try? await Task.sleep(for: .seconds(2))
      if !Task.isCancelled && isPlaying {
        await MainActor.run {
          withAnimation(.easeOut(duration: 0.3)) {
            self.showControls = false
          }
        }
      }
    }
  }
}

// MARK: - 탭 제스처 메서드
extension VideoViewModel {
  func leftTab() {
    let now = Date()
    let timeTap = now.timeIntervalSince(lastTapTime)

    if timeTap < doubleTap {
      // 더블탭: 싱글탭 Task 취소하고 3초 뒤로 이동
      singleTapTask?.cancel()

      // 비디오 시작 부분(0초)이면 더블탭 무시
      if currentTime <= 0 {
        lastTapTime = now
        return
      }

      seekToTime(to: currentTime - 3)
      tapCount += 1

      // 컨트롤 숨기기
      withAnimation(.easeOut(duration: 0.2)) {
        showControls = false
      }

      // 더블탭 애니메이션 표시
      showDoubleTapSeekIndicator(isForward: false)
    } else {
      // 싱글탭 대기: 0.5초 후 더블탭이 없으면 컨트롤 토글
      tapCount = 1

      singleTapTask?.cancel()
      singleTapTask = Task {
        try? await Task.sleep(for: .seconds(doubleTap))
        if !Task.isCancelled {
          await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
              self.showControls.toggle()
            }

            // 컨트롤을 켰고 재생 중이면 자동 숨김 타이머 시작
            if self.showControls && self.isPlaying {
              self.startAutoHideControls()
            }
          }
        }
      }
    }
    lastTapTime = now
  }
  
  func rightTap() {
    let now = Date()
    let timeTap = now.timeIntervalSince(lastTapTime)

    if timeTap < doubleTap {
      // 더블탭: 싱글탭 Task 취소하고 3초 앞으로 이동
      singleTapTask?.cancel()

      // 비디오 끝 부분이면 더블탭 무시
      if currentTime >= duration {
        lastTapTime = now
        return
      }

      seekToTime(to: currentTime + 3)
      tapCount += 1

      // 컨트롤 숨기기
      withAnimation(.easeOut(duration: 0.2)) {
        showControls = false
      }

      // 더블탭 애니메이션 표시
      showDoubleTapSeekIndicator(isForward: true)
    } else {
      // 싱글탭 대기: 0.5초 후 더블탭이 없으면 컨트롤 토글
      tapCount = 1

      singleTapTask?.cancel()
      singleTapTask = Task {
        try? await Task.sleep(for: .seconds(doubleTap))
        if !Task.isCancelled {
          await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
              self.showControls.toggle()
            }

            // 컨트롤을 켰고 재생 중이면 자동 숨김 타이머 시작
            if self.showControls && self.isPlaying {
              self.startAutoHideControls()
            }
          }
        }
      }
    }
    lastTapTime = now
  }

  func centerTap() {
    withAnimation(.easeInOut(duration: 0.3)) {
      self.showControls.toggle()
    }

    // 컨트롤을 켰고 재생 중이면 자동 숨김 타이머 시작
    if showControls && isPlaying {
      startAutoHideControls()
    }
  }

  // MARK: 더블탭 애니메이션 표시
  func showDoubleTapSeekIndicator(isForward: Bool) {
    // 기존 타이머 취소
    seekIndicatorTask?.cancel()

    if isForward {
      rightSeekCount += 1
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        showRightSeekIndicator = true
        showLeftSeekIndicator = false
      }
    } else {
      leftSeekCount += 1
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        showLeftSeekIndicator = true
        showRightSeekIndicator = false
      }
    }

    // 0.8초 후 인디케이터 숨기기
    seekIndicatorTask = Task {
      try? await Task.sleep(for: .seconds(0.8))
      if !Task.isCancelled {
        await MainActor.run {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            self.showLeftSeekIndicator = false
            self.showRightSeekIndicator = false
          }
          // 카운터 초기화
          self.leftSeekCount = 0
          self.rightSeekCount = 0
        }
      }
    }
  }
}
