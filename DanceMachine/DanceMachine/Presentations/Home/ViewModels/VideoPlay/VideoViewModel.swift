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
  
  // 탭 제스처 관련
  var lastTapTime: Date = Date()
  var tapCount: Int = .zero
  var autoShowControls: Task<Void, Never>?
  private let doubleTap: TimeInterval = 0.5
  
  var loadingProgress: Double = 0.0
  var isLoading: Bool = false
  var isDownloading: Bool = false
  
  // 배속 변수
  var playbackSpeed: Float = 1.0
}

// MARK: - 영상관련 메서드
extension VideoViewModel {
  // MARK: 동영상 Player 설정 (AVFoundation)
  func setupPlayer(from videoURL: String, videoId: String) async throws {
    await MainActor.run {
      self.isLoading = true
      self.loadingProgress = 0.0
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
        forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
        queue: DispatchQueue.main,
        using: { [weak self] time in
          self?.currentTime = time.seconds
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
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        withAnimation(.easeInOut(duration: 0.6)) {
          self.showControls = true
        }
      }
    } else {
      player?.play()
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        withAnimation(.easeInOut(duration: 0.6)) {
          self.showControls = false
        }
      }
      player?.rate = playbackSpeed
    }
    isPlaying.toggle()
  }
}

// MARK: - 탭 제스처 메서드
extension VideoViewModel {
  func leftTab() {
    let now = Date()
    let timeTap = now.timeIntervalSince(lastTapTime)
    
    if timeTap < doubleTap {
      seekToTime(to: currentTime - 5)
      tapCount += 1
      
      self.showControls = false
      
      self.autoShowControls?.cancel()
      
      self.autoShowControls = Task {
        try? await Task.sleep(for: .seconds(0.5))
        if !Task.isCancelled {
          await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
              self.showControls = true
            }
          }
        }
      }
    } else {
      tapCount = 1
      
      withAnimation(.easeInOut(duration: 0.3)) {
        self.showControls.toggle()
      }
    }
    lastTapTime = now
  }
  
  func rightTap() {
    let now = Date()
    let timeTap = now.timeIntervalSince(lastTapTime)
    
    if timeTap < doubleTap {
      seekToTime(to: currentTime + 5)
      tapCount += 1
      
      self.showControls = false
      
      self.autoShowControls?.cancel()
      
      self.autoShowControls = Task {
        try? await Task.sleep(for: .seconds(0.5))
        if !Task.isCancelled {
          await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
              self.showControls = true
            }
          }
        }
      }
    } else {
      tapCount = 1
      
      withAnimation(.easeInOut(duration: 0.3)) {
        self.showControls.toggle()
      }
    }
    lastTapTime = now
  }
}
