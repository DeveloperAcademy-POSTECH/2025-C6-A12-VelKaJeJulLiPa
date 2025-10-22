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
  
  var isLoading: Bool = false
  var errorMsg: String? = nil
  
  // MARK: 노티 메서드
  func notify(_ name: Foundation.Notification.Name) {
    NotificationCenter.default.post(name: name, object: nil)
  }
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
      
      await MainActor.run {
        self.isLoading = false
        print("track 이동 성공")
      }
      
      self.notify(.sectionDidUpdate)
      
    } catch { // TODO: 에러처리
      await MainActor.run {
        self.isLoading = false
        self.errorMsg = "섹션 변경에 실패했습니다"
      }
    }
  }
}
