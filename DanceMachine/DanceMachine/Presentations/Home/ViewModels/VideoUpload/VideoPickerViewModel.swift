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
  private let progressManager = VideoProgressManager.shared
  private let dataCacheManager = VideoCacheManager.shared
  private let cleanupService = UploadCleanupService()
  private let compressionManager = VideoCompressionManager.shared

  var videos: [PHAsset] = []
  var selectedAsset: PHAsset? = nil

  var player: AVPlayer?
  var videoTitle: String = ""
  var videoDuration: Double = 0

  var isLoading: Bool = false
  var errorMessage: String? = nil
  var showSuccessAlert: Bool = false

  var photoLibraryStatus: PHAuthorizationStatus = .notDetermined

  // iCloud 다운로드 상태
  var isDownloadingFromCloud: Bool = false
  var downloadProgress: Double = 0.0

  // 업로드 성공한 비디오/트랙 (VideoListView에서 감지)
  var lastUploadedVideo: Video? = nil
  var lastUploadedTrack: Track? = nil

  // 실패 시 재시도용 정보
  private var failedContext: (
    videoId: String,
    tracksId: String,
    sectionId: String,
    tempURL: URL
  )? = nil

  var isUploading: Bool {
    if case .uploading = progressManager.uploadState { return true }
    return false
  }
  
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
  func exportVideo(tracksId: String, sectionId: String, onDownloadComplete: @escaping () -> Void) {
    self.isLoading = true
    self.cleanupPlayer() // 재생중에 업로드 버튼 누를시 계속 재생되는 현상
    
    // PHAsset 에서 비디오 파일 추출
    let o = PHVideoRequestOptions()
    o.isNetworkAccessAllowed = true // iCloud에 있어도 다운로드
    o.deliveryMode = .highQualityFormat // 고화질 요청

    // iCloud 다운로드 진행률 추적
    o.progressHandler = { progress, error, stop, info in
      Task { @MainActor in
        self.isDownloadingFromCloud = true
        self.downloadProgress = progress
        print("iCloud 다운로드 중: \(Int(progress * 100))%")

        if let error = error {
          print("iCloud 다운로드 에러: \(error.localizedDescription)")
          self.isDownloadingFromCloud = false
          self.isLoading = false
        }
      }
    }

    PHImageManager.default().requestAVAsset(
      forVideo: selectedAsset ?? PHAsset(),
      options: o) { av, audioMix, info in

        // iCloud 다운로드 중인지 체크 (첫 번째 콜백)
        if let isInCloud = info?[PHImageResultIsInCloudKey] as? Bool, isInCloud {
          print("iCloud에서 다운로드 시작...")
          return  // 두 번째 콜백 기다림
        }

        // 다운로드 에러 체크
        if let error = info?[PHImageErrorKey] as? Error {
          Task { @MainActor in
            self.isDownloadingFromCloud = false
            self.isLoading = false
            print("PHAsset 가져오기 실패: \(error.localizedDescription)")
          }
          return
        }

        guard let urlAsset = av as? AVURLAsset else {
          Task { @MainActor in
            self.isDownloadingFromCloud = false
            self.isLoading = false
            print("AVURLAsset 변환 실패")
          }
          return
        }

        // iCloud 다운로드 완료 -> 피커 닫기
        Task { @MainActor in
          self.isDownloadingFromCloud = false
          print("Cloud 다운로드 완료")
          onDownloadComplete()
        }

        Task {
          let videoId = UUID().uuidString

          do {
            let duration = try await self.getDuration(from: urlAsset)
            
            await MainActor.run {
              self.progressManager.startCompressing()
            }
            // 압축
            let compressionURL = try await self.compressionManager.compressIfNeeded(
              urlAsset,
              outputFileName: videoId) { progress in
                Task { @MainActor in
                  self.progressManager.updatedCompressionProgress(progress)
                }
              }
            
            await MainActor.run {
              self.progressManager.startUpload()
            }
            
            let (video, track) = try await self.generateVideo( 
              videoURL: compressionURL,
              duration: duration,
              tracksId: tracksId,
              sectionId: sectionId,
              videoId: videoId,
              uploaderId: FirebaseAuthManager.shared.userInfo?.userId ?? ""
            )

            await MainActor.run {
              self.lastUploadedVideo = video
              self.lastUploadedTrack = track
              self.progressManager.finishUpload()
              self.compressionManager.deleteTempFile(compressionURL)
              self.isLoading = false
              self.showSuccessAlert = true
            }

          } catch let error as VideoError {
            // 실패 시 임시 파일 복사 (재시도용)
//            let tempURL = try? await self.copyToTemp(urlAsset, videoId: videoId)

            await MainActor.run {
              self.isLoading = false
            }
            switch error {
            case .fileTooLarge: // 파일 너무 클때
              self.progressManager.fileTooLarge(message: error.userMsg)
            case .compressionError, .uploadFailed, .networkError, .uploadTimeout: // 그 외 실패
              self.failedContext = (videoId, tracksId, sectionId, urlAsset.url)
              self.progressManager.failUpload(message: error.userMsg)
            default:
              self.progressManager.failUpload(message: error.userMsg)
            }
          } catch {
            // 실패 시 임시 파일 복사 (재시도용)
            let tempURL = try? await self.copyToTemp(urlAsset, videoId: videoId)

            await MainActor.run {
              self.isLoading = false
              if let url = tempURL {
                self.failedContext = (videoId, tracksId, sectionId, url)
              }
              self.progressManager.failUpload(message: "업로드 실패")
            }
          }
        }
      }
  }
  
  private func generateVideo(
    videoURL: URL,
    duration: Double,
    tracksId: String,
    sectionId: String,
    videoId: String,
    uploaderId: String,
  ) async throws -> (Video, Track) {
    
    let videoData = try Data(contentsOf: videoURL)
    let trackId = UUID().uuidString

    // 썸네일 생성
    let asset = AVURLAsset(url: videoURL)
    let thumbnailImage = try await self.generateThumbnail(from: asset)
    guard let thumbData = thumbnailImage?.jpegData(compressionQuality: 0.8) else {
      throw VideoError.thumbnailFailed
    }

    // 스토리지 업로드
    let (videoURL, thumbnailURL) = try await uploadStorage(
      videoData: videoData,
      thumbData: thumbData,
      videoId: videoId,
      duration: duration
    )

    // Video 객체 생성
    let video = Video(
      videoId: UUID(uuidString: videoId) ?? UUID(),
      videoTitle: videoTitle,
      videoDuration: duration,
      videoURL: videoURL,
      thumbnailURL: thumbnailURL,
      uploaderId: uploaderId
    )

    // Track 객체 생성
    let track = Track(
      trackId: trackId,
      videoId: videoId,
      sectionId: sectionId
    )

    // Firestore에 저장
    try await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask {
        try await self.store.create(video)
        print("Video 문서 생성")
      }
      group.addTask {
        try await self.store.createToSubSubcollection(
          track,
          in: .tracks,
          grandParentId: tracksId,
          withIn: .section,
          parentId: sectionId,
          subCollection: .track,
          strategy: .create
        )
        print("Track 문서 생성")
      }
      try await group.waitForAll()
    }
    // 썸네일 캐싱
    if let thumb = thumbnailImage {
      await dataCacheManager.cacheThumbnailForImage(
        thumb,
        videoId: videoId
      )
    }
    return (video, track)
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
    thumbnailURL: String,
    uploaderId: String
  ) async throws {
    
    let video = Video(
      videoId: UUID(uuidString: videoId) ?? UUID(),
      videoTitle: videoTitle,
      videoDuration: duration,
      videoURL: downloadURL,
      thumbnailURL: thumbnailURL,
      uploaderId: uploaderId
    )
    
    try await store.create(video)
  }
  // MARK: - 스토리지 업로드 + url 추출 + Video 컬렉션 생성
  private func uploadStorage(
    videoData: Data,
    thumbData: Data,
    videoId: String,
    duration: Double
  ) async throws -> (videoURL: String, thumbnailURL: String) {

    var videoProgress: Double = 0
    var thumbProgress: Double = 0

    func updateTotalProgress() {
      Task { @MainActor in
        let totalProgress = (videoProgress * 0.8) + (thumbProgress * 0.2)
        progressManager.updateProgress(totalProgress)
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

      return (vU, thumbU)

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

  // MARK: - 재시도/취소

  /// 재시도
  func retryUpload() async {
    guard let context = failedContext else { return }

    await MainActor.run {
      self.isLoading = true
      self.progressManager.startCompressing()
    }

    // 기존 데이터 정리
    await cleanupService.cleanupFailedUpload(
      videoId: context.videoId,
      tracksId: context.tracksId,
      sectionId: context.sectionId
    )

    // 재업로드
    do {
      let asset = AVURLAsset(url: context.tempURL)
      let duration = try await getDuration(from: asset)
      
      let compreesionURL = try await compressionManager.compressIfNeeded(
        asset,
        outputFileName: context.videoId) { progress in
          Task { @MainActor in
            self.progressManager.updatedCompressionProgress(progress)
          }
        }
      
      await MainActor.run {
        self.progressManager.startUpload()
      }

      let (video, track) = try await generateVideo(
        videoURL: compreesionURL,
        duration: duration,
        tracksId: context.tracksId,
        sectionId: context.sectionId,
        videoId: context.videoId,
        uploaderId: FirebaseAuthManager.shared.userInfo?.userId ?? ""
      )

      await MainActor.run {
        self.lastUploadedVideo = video
        self.lastUploadedTrack = track
        self.progressManager.finishUpload()
        self.deleteTempFile(context.tempURL)
        self.failedContext = nil
        self.isLoading = false
        self.showSuccessAlert = true
      }
    } catch let error as VideoError {
      await MainActor.run {
        self.isLoading = false
        self.progressManager.failUpload(message: error.userMsg)
      }
    } catch {
      await MainActor.run {
        self.isLoading = false
        self.progressManager.failUpload(message: "재시도 실패")
      }
    }
  }

  /// 취소
  func cancelUpload() async {
    if let context = failedContext {
      // 데이터 정리
      await cleanupService.cleanupFailedUpload(
        videoId: context.videoId,
        tracksId: context.tracksId,
        sectionId: context.sectionId
      )
      deleteTempFile(context.tempURL)

      await MainActor.run {
        self.failedContext = nil
      }
    }

    // failedContext 없어도 progress는 초기화
    await MainActor.run {
      self.progressManager.reset()
    }
  }

  // MARK: - 임시 파일

  private func copyToTemp(_ asset: AVURLAsset, videoId: String) async throws -> URL {
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(videoId).mov")
    if FileManager.default.fileExists(atPath: tempURL.path) {
      try? FileManager.default.removeItem(at: tempURL)
    }
    try FileManager.default.copyItem(at: asset.url, to: tempURL)
    return tempURL
  }

  private func deleteTempFile(_ url: URL) {
    try? FileManager.default.removeItem(at: url)
  }
}
// MARK: - 권한 설정 관련
extension VideoPickerViewModel {
  func requestPermissionAndFetch() async {
    if ProcessInfo.isRunningInPreviews { return } // 프리뷰 전용
    
    let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    
    await MainActor.run {
      self.photoLibraryStatus = currentStatus
    }
    
    if currentStatus == .authorized || currentStatus == .limited {
      self.fetchVideos()
      return
    }
    
    PHPhotoLibrary.requestAuthorization(for: .readWrite) {
      status in
      Task { @MainActor in
        self.photoLibraryStatus = status
      }
      switch status {
      case .authorized, .limited:
        self.fetchVideos()
      case .denied, .restricted, .notDetermined:
        print("사진 라이브러리 접근 거부 또는 제한")
      @unknown default:
        print("알 수 없는 권한 상태")
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
  
  func openSettings() {
    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
      return
    }
    
    if UIApplication.shared.canOpenURL(settingsURL) {
      UIApplication.shared.open(settingsURL)
    }
  }
}

