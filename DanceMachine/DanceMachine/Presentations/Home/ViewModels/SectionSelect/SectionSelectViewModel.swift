//
//  SectionSelectViewModel.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/21/25.
//

import Foundation

@Observable
final class SectionSelectViewModel {
  private let store = FirestoreManager.shared
  private let dataCacheManager = VideoDataCacheManager.shared
  
  var isLoading: Bool = false
  var errorMsg: String? = nil
  var showAlert: Bool = false
}

extension SectionSelectViewModel {
  func updateTrack(
    track: Track,
    newSectionId: String,
    tracksId: String,
    oldSectionId: String
  ) async {
    await MainActor.run {
      self.isLoading = true
      self.errorMsg = nil
    }
    
    do {
      try await store.deleteFromSubSubcollection(
        in: .tracks,
        grandParentId: tracksId,
        withIn: .section,
        parentId: oldSectionId,
        subCollection: .track,
        target: track.trackId
      )
      
      let updatedTrack = Track(
        trackId: track.trackId,
        videoId: track.videoId,
        sectionId: newSectionId
      )
      
      try await store.createToSubSubcollection(
        updatedTrack,
        in: .tracks,
        grandParentId: tracksId,
        withIn: .section,
        parentId: newSectionId,
        subCollection: .track,
        strategy: .create
      )
      
      await dataCacheManager.moveTrack(
        trackId: track.trackId,
        toSectionId: newSectionId,
        in: tracksId
      )
      
      await MainActor.run {
        self.isLoading = false
        self.showAlert = true
        self.errorMsg = "영상 이동에 성공했습니다!"
        print("track 이동 성공")
      }
      
    } catch { // TODO: 에러처리
      await MainActor.run {
        self.isLoading = false
        self.showAlert = true
        self.errorMsg = "영상 이동에 실패했습니다"
      }
    }
  }
}
