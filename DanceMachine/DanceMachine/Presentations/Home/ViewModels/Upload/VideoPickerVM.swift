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
final class VideoPickerVM {
  
  private let store = FirestoreManager.shared
  private let storage = FireStorageManager.shared
  
  var selectedAsset: PHAsset? = nil
  
  var player: AVPlayer?
  var videoTitle: String = ""
  var videoThumbnail: UIImage? = nil
  var videoDuration: Double = 0
  var localVideoURL: URL? = nil
  
  var isLoading: Bool = false
  
  // MARK: 동영상 미리보기 로드
  func loadVideo() {
    self.isLoading = true
    
    let o = PHVideoRequestOptions()
    o.isNetworkAccessAllowed = true
    
    PHImageManager.default().requestPlayerItem(
      forVideo: selectedAsset ?? PHAsset(),
      options: o) { item, _ in
        if let pItem = item {
          self.player = AVPlayer(playerItem: pItem)
          self.isLoading = false
        }
      }
  }
}

// MARK: 비디오 업로드 관련
extension VideoPickerVM {
  func exportVideo() {
    self.isLoading = true
    defer { self.isLoading = false }
    
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
            
            async let t = self.generateThumbnail(from: urlAsset)
            async let _ = self.generateVideo(from: urlAsset, duration: duration)
            
            let thumbnail = try await t
            
            await MainActor.run {
              self.videoThumbnail = thumbnail
              self.videoDuration = duration
              print("업로드 성공")
            }
            
          } catch {
            await MainActor.run {
              print("업로드 실패")
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
    duration: Double
  ) async throws {
    
    let videoData = try Data(contentsOf: asset.url)
    let videoId = UUID()
    
    let path = try await self.storage.uploadVideo(
      data: videoData,
      videoId: videoId
    )
    let downloadURL = try await self.storage.getDownloadURL(for: path)
    
    let video = Video(
      videoId: videoId,
      videoTitle: "제목", // TODO: 비디오 이름
      videoDuration: duration,
      videoURL: downloadURL
    )
    
    try await store.create(video)
  }
  
  private func generateThumbnail(
    from asset: AVURLAsset
  ) async throws -> UIImage? {
    
    let imageG = AVAssetImageGenerator(asset: asset)
    imageG.appliesPreferredTrackTransform = true
    
    let t = CMTime(seconds: 1, preferredTimescale: 60)
    
    let (cgImage, _) = try await imageG.image(at: t)
    return UIImage(cgImage: cgImage)
  }
  
  private func getDuration(
    from asset: AVURLAsset
  ) async throws -> Double {
    
    let d = try await asset.load(.duration)
    return CMTimeGetSeconds(d)
  }
}
