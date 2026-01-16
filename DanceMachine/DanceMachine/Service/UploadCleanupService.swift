//
//  UploadCleanupService.swift
//  DanceMachine
//
//  Created by Claude on 11/8/25.
//

import Foundation

/// 업로드 실패 시 잔여 데이터 정리
final class UploadCleanupService {

  private let firestore = FirestoreManager.shared
  private let storage = FireStorageManager.shared
  private let cacheManager = ListDataCacheManager.shared

  func cleanupFailedUpload(
    videoId: String,
    tracksId: String,
    sectionId: String
  ) async {
    print("🧹 [Cleanup] 시작 - videoId: \(videoId)")

    await withTaskGroup(of: Void.self) { group in
      // Track 삭제
      group.addTask {
        do {
          let tracks: [Track] = try await self.firestore.fetchAllFromSubSubcollection(
            in: .tracks,
            grandParentId: tracksId,
            withIn: .section,
            parentId: sectionId,
            subCollection: .track
          )

          if let track = tracks.first(where: { $0.videoId == videoId }) {
            try await self.firestore.deleteFromSubSubcollection(
              in: .tracks,
              grandParentId: tracksId,
              withIn: .section,
              parentId: sectionId,
              subCollection: .track,
              target: track.trackId
            )
            print("[Cleanup] Track 삭제 완료: \(track.trackId)")
          } else {
            print("[Cleanup] Track 없음 (생성 안됨 또는 이미 삭제됨)")
          }
        } catch {
          print("[Cleanup] Track 삭제 실패: \(error)")
        }
      }

      // Video 삭제
      group.addTask {
        do {
          try await self.firestore.delete(collectionType: .video, documentID: videoId)
          print("[Cleanup] Video 문서 삭제 완료")
        } catch {
          print("[Cleanup] Video 문서 삭제 실패: \(error)")
        }
      }

      // Storage 비디오 삭제
      group.addTask {
        do {
          _ = try await self.storage.deleteVideo(at: "video/\(videoId)/\(videoId).video.mov")
          print("[Cleanup] Storage 비디오 파일 삭제 완료")
        } catch {
          print("[Cleanup] Storage 비디오 파일 삭제 실패 (파일 없음): \(error)")
        }
      }

      // Storage 썸네일 삭제
      group.addTask {
        do {
          _ = try await self.storage.deleteVideo(at: "video/\(videoId)/\(videoId).jpg")
          print("[Cleanup] Storage 썸네일 삭제 완료")
        } catch {
          print("[Cleanup] Storage 썸네일 삭제 실패 (파일 없음): \(error)")
        }
      }

      // 캐시 삭제
      group.addTask {
        await self.cacheManager.removeVideo(videoId: videoId, from: tracksId)
        print("[Cleanup] 캐시 삭제 완료")
      }
    }

    print("[Cleanup] 완료 - videoId: \(videoId)")
  }
}
