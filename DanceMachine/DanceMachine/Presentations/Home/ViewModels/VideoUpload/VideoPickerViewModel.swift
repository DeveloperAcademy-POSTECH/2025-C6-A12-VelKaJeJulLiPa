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
//  var videoThumbnail: UIImage? = nil
  var videoDuration: Double = 0
  var localVideoURL: URL? = nil
  
  var isLoading: Bool = false
  var errorMessage: String? = nil
  var showSuccessAlert: Bool = false
  
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
extension VideoPickerVM {
  func exportVideo(tracksId: String) {
    self.isLoading = true
    
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
              tracksId: tracksId
            )
            
            await MainActor.run {
//              self.videoThumbnail = thumbnail
              self.videoDuration = duration
              self.isLoading = false
              self.showSuccessAlert = true
              print("비디오 업로드 성공")
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
        
        //        Task {
        //          // 임시 폴더로 복사
        //          let fileName = "video_\(UUID().uuidString).mov"
        ////          guard let asset = self.selectedAsset else { return }
        ////          let sanitizedID = asset.localIdentifier
        ////            .replacingOccurrences(of: "/", with: "_")
        ////            .replacingOccurrences(of: "\\", with: "_")
        ////          let fileName = "video_\(sanitizedID).mov"
        //          let tempURL = URL.temporaryDirectory.appending(component: fileName)
        //
        //          do {
        //            if FileManager.default.fileExists(atPath: tempURL.path()) {
        //              try FileManager.default.removeItem(at: tempURL)
        //              print("임시 디렉토리 삭제")
        //            }
        //            try FileManager.default.copyItem(at: urlAsset.url, to: tempURL)
        //            print("\(tempURL.path()) 임시 디렉토리 추가")
        //
        //            async let t = self.generateThumbnail(
        //              from: urlAsset
        //            )
        //            async let d = self.getDuration(
        //              from: urlAsset
        //            )
        //
        //            let (thumbnail, duration) = try await (t, d)
        //
        //            await MainActor.run {
        //              self.localVideoURL = tempURL
        //              self.videoThumbnail = thumbnail
        //              self.videoDuration = duration
        //            }
        //          } catch {
        //            print("비디오 복사 실패")
        //          }
        //        }
      }
  }
  
  private func generateVideo(
    from asset: AVURLAsset,
    duration: Double,
    tracksId: String
  ) async throws {
    // 1. 비디오 데이터로 변환
    let videoData = try Data(contentsOf: asset.url)
    
    let videoId = UUID()
    let sectionId = UUID()
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
            sectionId: sectionId,
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
          try await self.createSectionAndTrack(
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
  // MARK: Section -> Track 순차 생성 (의존성)
  private func createSectionAndTrack(
    tracksId: String,
    sectionId: UUID,
    videoId: UUID
  ) async throws {
    
    try await self.createSection(
      in: tracksId,
      from: sectionId.uuidString
    )
    
    try await self.createTrack(
      in: tracksId,
      withIn: sectionId.uuidString,
      to: videoId.uuidString
    )
  }
  // MARK: 서브컬렉션 Section 생성 메서드
  private func createSection(
    in tracksId: String,
    from sectionId: String
  ) async throws{
    
    let section = Section(
      sectionId: sectionId,
      sectionTitle: "경로 미지정"
    )
    
    try await store.createToSubcollection(
      section,
      under: .tracks,
      parentId: tracksId,
      subCollection: .section,
      strategy: .create
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
    videoId: UUID,
    duration: Double,
    downloadURL: String,
    thumbnailURL: String
  ) async throws {
    
    let video = Video(
      videoId: videoId,
      videoTitle: "제목", // TODO: 비디오 이름
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
    videoId: UUID,
    sectionId: UUID,
    duration: Double
  ) async throws{
    
    async let v = storage.uploadStorage(
      data: videoData,
      type: .video(videoId.uuidString)
    )
    async let t = storage.uploadStorage(
      data: thumbData,
      type: .thumbnail(videoId.uuidString)
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
extension VideoPickerVM {
  func requestPermissionAndFetch() {
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

