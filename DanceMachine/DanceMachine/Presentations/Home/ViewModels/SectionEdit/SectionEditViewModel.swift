//
//  SectionEditViewModel.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/17/25.
//

import Foundation

@Observable
final class SectionEditViewModel {
  private let store = FirestoreManager.shared
  private let storage = FireStorageManager.shared
  private let dataCacheManager = VideoDataCacheManager.shared
  
  var sections: [Section]
  var editingSectionid: String? = nil
  var editText: String = ""

  var isNewSection: Bool = false // 수정모드와 추가모드 플래그

  private let initialSections: [Section] // 초기 상태 저장

  init(sections: [Section]) {
    self.sections = sections
    self.initialSections = sections
  }

  // 편집/추가 모드인지 체크 (간단 버전)
  var isEditing: Bool {
    editingSectionid != nil
  }
  
  func startEdit(section: Section) {
    editingSectionid = section.sectionId
    editText = section.sectionTitle
    isNewSection = false
  }
  
  func addNewSection() {
    let new = Section(
      sectionId: UUID().uuidString,
      sectionTitle: ""
    )
    sections.append(new)
    
    // 편집모드 진입
    self.editText = ""
    self.editingSectionid = new.sectionId
    self.isNewSection = true
  }
}
// MARK: - 수정 업데이트 등 서버 연동 메서드
extension SectionEditViewModel {
  // MARK: 섹션 업데이트 메서드
  func updateSection(
    tracksId: String,
    section: Section
  ) async {
    guard !editText.isEmpty else { return }
    guard editText != "일반" else { return }
    
    var updatedSection = section
    updatedSection.sectionTitle = self.editText
    
    do {
      //
      let strategy: WriteStrategy = self.isNewSection ? .create : .update
      try await store.createToSubcollection(
        updatedSection,
        under: .tracks,
        parentId: tracksId,
        subCollection: .section,
        strategy: strategy
      )
      
      if isNewSection {
        await dataCacheManager.addSection(
          updatedSection,
          to: tracksId
        )
      } else {
        await dataCacheManager.updateSectionTitle(
          sectionId: updatedSection.sectionId,
          newTitle: self.editText,
          in: tracksId
        )
      }
      
      await MainActor.run {
        if let index = sections.firstIndex(where: { $0.sectionId == section.sectionId }) {
          sections[index] = updatedSection
        }
        self.editText = ""
        self.editingSectionid = nil
        self.isNewSection = false
      }
    } catch { // TODO: 에러처리
      print("섹션 수정 실패")
    }
  }
  // MARK: 섹션 추가 메서드
  func addSection(
    tracksId: String,
    title: String
  ) async {
    let newSection = Section(
      sectionId: UUID().uuidString,
      sectionTitle: title
    )
    
    do {
      try await store.createToSubcollection(
        newSection,
        under: .tracks,
        parentId: tracksId,
        subCollection: .section,
        strategy: .create
      )
      
      // 캐시 추가
      await dataCacheManager.addSection(
        newSection,
        to: tracksId
      )
      
    } catch { // TODO: 에러 처리
      print("섹션 추가 실패: \(error)")
    }
  }
  // MARK: 섹션 삭제 메서드 (하위 track, video, storage 파일도 함께 삭제)
  func deleteSection(
    tracksId: String,
    section: Section
  ) async {
    do {
      // 1. 섹션에 속한 모든 track 가져오기
      let tracks: [Track] = try await store.fetchAllFromSubSubcollection(
        in: .tracks,
        grandParentId: tracksId,
        withIn: .section,
        parentId: section.sectionId,
        subCollection: .track
      )
      
      // 2. 각 track의 video와 storage 파일 삭제
      for track in tracks {
        let videoId = track.videoId
        
        // Storage에서 영상과 썸네일 삭제 (병렬 처리)
        try? await withThrowingTaskGroup(of: Void.self) { group in
          group.addTask {
            _ = try await self.storage.deleteVideo(
              at: "video/\(videoId)/\(videoId).video.mov"
            )
            print("\(videoId): 스토리지 영상 삭제")
          }
          group.addTask {
            _ = try await self.storage.deleteVideo(
              at: "video/\(videoId)/\(videoId).jpg"
            )
            print("\(videoId): 스토리지 썸네일 삭제")
          }
          try await group.waitForAll()
        }
        
        // DB에서 video 삭제
        try? await store.delete(
          collectionType: .video,
          documentID: videoId
        )
        print("\(videoId): DB 영상 삭제")
        
        // DB에서 track 삭제
        try? await store.deleteFromSubSubcollection(
          in: .tracks,
          grandParentId: tracksId,
          withIn: .section,
          parentId: section.sectionId,
          subCollection: .track,
          target: track.trackId
        )
        print("\(videoId): DB 트랙 삭제")
      }
      
      // 3. DB에서 섹션 삭제
      try await store.deleteFromSubcollection(
        under: .tracks,
        parentId: tracksId,
        subCollection: .section,
        target: section.sectionId
      )
      print("\(section.sectionTitle) 삭제")
      
      // 4. 캐시에서 섹션과 하위 데이터 삭제
      await dataCacheManager.removeSectionWithVideos(
        sectionId: section.sectionId,
        from: tracksId
      )
      
      await MainActor.run {
        sections.removeAll { $0.sectionId == section.sectionId }
      }
    } catch { // TODO: 에러 처리
      print("섹션 삭제 실패: \(error)")
    }
  }
}
// MARK: - 프리뷰 전용 목데이터
extension SectionEditViewModel {
  static var preview: SectionEditViewModel {
    let vm = SectionEditViewModel(
      sections: [
        Section(sectionId: "ㅇㅇ", sectionTitle: "A구간"),
        Section(sectionId: "ㅇㅇd", sectionTitle: "B구간"),
        Section(sectionId: "ㅇㅇdd", sectionTitle: "C구간")],
    )
    
    return vm
  }
}
