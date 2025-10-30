//
//  VideoPickerVM.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/7/25.
//

import Foundation
import Photos
import AVKit

@Observable
final class VideoPickerViewModel {
  
  private let store = FirestoreManager.shared
  private let storage = FireStorageManager.shared
  
  var videos: [PHAsset] = [] // 이미지 및 비디오, 라이브포토를 나타내는 모델
  var selectedAsset: PHAsset? = nil // 선택된 에셋
  
  var player: AVPlayer?
  var videoTitle: String = ""
  var videoDuration: Double = 0

  
  var isLoading: Bool = false
  var errorMessage: String? = nil
  var showSuccessAlert: Bool = false
  var uploadProgress: Double = 0.0
  
  // MARK: 동영상 미리보기 로드
  func loadVideo() {
    self.cleanupPlayer()
    self.isLoading = true
    
    let o = PHVideoRequestOptions()
    o.isNetworkAccessAllowed = true
    
    PHImageManager.default().requestPlayerItem(
      forVideo: selectedAsset ?? PHAsset(),
      options: o) { item, _ in
        if let pItem = item {
          Task { @MainActor in
            self.player = AVPlayer(playerItem: pItem)
            self.isLoading = false              
          }
        }
      }
  }
  // MARK: player 정리
  func cleanupPlayer() {
    player?.pause()
    player?.replaceCurrentItem(with: nil)
    player = nil
  }
}

// MARK: 비디오 업로드 관련
extension VideoPickerViewModel {
  func exportVideo(tracksId: String, sectionId: String) {
    self.isLoading = true
    self.cleanupPlayer() // 재생중에 업로드 버튼 누를시 계속 재생되는 현상 
    
    // PHAsset 에서 비디오 파일 추출
    let o = PHVideoRequestOptions()
    o.isNetworkAccessAllowed = true // iCloud에 있어도 다운로드
    o.deliveryMode = .highQualityFormat // 화질
    
    PHImageManager.default().requestAVAsset(
      forVideo: selectedAsset ?? PHAsset(),
      options: o) {
        av,
        _,
        _ in
        guard let urlAsset = av as? AVURLAsset else { return }
        
        Task {
          do {
            let duration = try await self.getDuration(from: urlAsset)
            
            try await self.generateVideo(
              from: urlAsset,
              duration: duration,
              tracksId: tracksId,
              sectionId: sectionId
            )
            
            await MainActor.run {
              self.videoDuration = duration
              self.isLoading = false
              self.showSuccessAlert = true
              print("비디오 업로드 성공")
              
              NotificationCenter.post(.videoUpload)
            }
            
          } catch let error as VideoError {
            await MainActor.run {
              self.isLoading = false
              self.errorMessage = error.userMsg
              print("Firestore 에러 : \(error.debugMsg)")
            }
          } catch {
            await MainActor.run {
              self.isLoading = false
              self.errorMessage = "비디오 업로드 중 오류가 발생했습니다"
              print("예상치 못한 에러: \(error)")
            }
          }
        }
      }
  }
  
  private func generateVideo(
    from asset: AVURLAsset,
    duration: Double,
    tracksId: String,
    sectionId: String
  ) async throws {
    // 1. 비디오 데이터로 변환
    let videoData = try Data(contentsOf: asset.url)
    
    let videoId = UUID().uuidString
//    let sectionId = UUID() // TODO: 테스트 후 삭제
    // 2. 썸네일 데이터로 변환
    let t = try await self.generateThumbnail(from: asset)
    guard let thumbData = t?.jpegData(compressionQuality: 0.8) else {
      throw VideoError.thumbnailFailed }
    
    try await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask {
        do {
          try await self.uploadStorage(
            videoData: videoData,
            thumbData: thumbData,
            videoId: videoId,
            duration: duration
          )
          print("스토리지 업로드 성공")
        } catch {
          print("스토리지 업로드 실패: \(error)")
          throw VideoError.uploadFailed
        }
      }
      group.addTask {
        do {
          try await self.createTrack(
            tracksId: tracksId,
            sectionId: sectionId,
            videoId: videoId
          )
          print("section -> track 컬렉션 생성 완료")
        } catch {
          print("section/track 생성 실패: \(error)")
          throw VideoError.createSectionFailed
        }
      }
      try await group.waitForAll()
    }
    
  }
  private func createTrack(
    tracksId: String,
    sectionId: String,
    videoId: String
  ) async throws {
    
    try await self.createTrack(
      in: tracksId,
      withIn: sectionId,
      to: videoId
    )
  }
  // MARK: 서브서브컬렉션 Track 생성 메서드
  private func createTrack(
    in tracksId: String,
    withIn sectionId: String,
    to videoId: String
  ) async throws {
    
    let trackId = UUID()
    let track = Track(
      trackId: trackId.uuidString,
      videoId: videoId,
      sectionId: sectionId
    )
    
    try await store.createToSubSubcollection(
      track,
      in: .tracks,
      grandParentId: tracksId,
      withIn: .section,
      parentId: sectionId,
      subCollection: .track,
      strategy: .create
    )
  }
  // MARK: 메인컬렉션 Video 생성 메서드
  private func createVideo(
    videoId: String,
    duration: Double,
    downloadURL: String,
    thumbnailURL: String
  ) async throws {
    
    let video = Video(
      videoId: UUID(uuidString: videoId) ?? UUID(),
      videoTitle: videoTitle,
      videoDuration: duration,
      videoURL: downloadURL,
      thumbnailURL: thumbnailURL
    )
    
    try await store.create(video)
  }
  // MARK: - 스토리지 업로드 + url 추출 + Video 컬렉션 생성
  private func uploadStorage(
    videoData: Data,
    thumbData: Data,
    videoId: String,
    duration: Double
  ) async throws{
    
    var videoProgress: Double = 0
    var thumbProgress: Double = 0
    
    func updateTotalProgress() {
      Task { @MainActor in
        self.uploadProgress = (videoProgress * 0.8) + (thumbProgress * 0.2)
      }
    }
    
    do {
      async let v = storage.uploadStorage(
        data: videoData,
        type: .video(videoId),
        progressHandler: { progress in
          videoProgress = progress
          updateTotalProgress()
        },
        timeout: 120.0
      )
      async let t = storage.uploadStorage(
        data: thumbData,
        type: .thumbnail(videoId),
        progressHandler: { progress in
          thumbProgress = progress
          updateTotalProgress()
        },
        timeout: 30.0
      )
      
      let (video, thumbnail) = try await (v, t)
      
      async let videoURL = self.getURL(url: video)
      async let thumbURL = self.getURL(url: thumbnail)
      
      let (vU, thumbU) = try await (videoURL, thumbURL)
      
      _ = try await self.createVideo(
        videoId: videoId,
        duration: duration,
        downloadURL: vU,
        thumbnailURL: thumbU
      )
      
    } catch let error as VideoError {
      throw error
    } catch {
      throw VideoError.networkError
    }
  }
  // MARK: - URL 추출 메서드
  private func getURL(
    url: String
  ) async throws -> String {
    let url = try await storage.getDownloadURL(for: url)
    return url
  }
  // MARK: - 영상에서 썸네일 추출 메서드
  private func generateThumbnail(
    from asset: AVURLAsset
  ) async throws -> UIImage? {
    
    let imageG = AVAssetImageGenerator(asset: asset)
    imageG.appliesPreferredTrackTransform = true
    
    let t = CMTime(seconds: 1, preferredTimescale: 60)
    
    let (cgImage, _) = try await imageG.image(at: t)
    return UIImage(cgImage: cgImage)
  }
  // MARK: - 영상 길이 추출 메서드
  private func getDuration(
    from asset: AVURLAsset
  ) async throws -> Double {
    
    let d = try await asset.load(.duration)
    return CMTimeGetSeconds(d)
  }
}
// MARK: - 권한 설정 관련
extension VideoPickerViewModel {
  func requestPermissionAndFetch() async {
#if DEBUG
    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
      Task { @MainActor in
        self.videos = []
      }
      return
    }
#endif
    PHPhotoLibrary.requestAuthorization(for: .readWrite) {
      status in
      switch status {
      case .authorized:
        self.fetchVideos()
      case .denied, .restricted:
        print("사진 라이브러리 접근 거부 또는 제한") // TODO: 처리 필요
      case .notDetermined:
        print("사용자가 아직 선택하지 않음") // TODO: 처리 필요
      case .limited:
        print("권한 제한") // TODO: 처리 필요
      @unknown default:
        fatalError("알 수 없는 권한 상태") // TODO: 처리 필요
      }
    }
  }
  
  private func fetchVideos() {
    // Asset 혹은 Collection 객체를 가져올 때 이들에 대한 필터링 및 정렬을 정의할 수 있는 객체
    let fetchO = PHFetchOptions()
    
    // NSPredicate 타입인 predicate를 사용하여 필터링을 정의하고,
    // NSSortDescriptor 타입인 sortDescriptors를 사용하여 정렬을 정의
    fetchO.sortDescriptors = [NSSortDescriptor(
      key: "creationDate",
      ascending: false
    )]
    
    let results = PHAsset.fetchAssets(
      with: .video,
      options: fetchO
    )
    
    var fetchedVideos: [PHAsset] = []
    results.enumerateObjects { (asset, _, _) in
      fetchedVideos.append(asset)
    }
    
    Task { @MainActor in
      self.videos = fetchedVideos
    }
  }
}

