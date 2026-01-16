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
  private let dataCacheManager = ListDataCacheManager.shared
  
  var sections: [Section]
  var editingSectionid: String? = nil
  var editText: String = ""
  
  var isLoading: Bool = false
  var errorMsg: String = ""

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
    
    await MainActor.run {
      self.isLoading = true
    }

    var updatedSection = section
    updatedSection.sectionTitle = self.editText
    
    do {
      // 테스트용: 네트워크 에러 시뮬레이션 (테스트 후 삭제할 것)
//       throw NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
//      throw SectionEditError.createError

      try await self.createSection(
        tracksId: tracksId,
        section: section,
        updateSection: updatedSection
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
        self.isLoading = false
      }
    } catch let error as SectionEditError {
      await MainActor.run {
        self.errorMsg = error.userMsg
        self.isLoading = false
      }
      NotificationCenter.post(.section(.sectionCRUDFailed))
      print(error.debugMsg)
    } catch {
      await MainActor.run {
        self.errorMsg = "네트워크 연결을 확인하고 다시 시도해 주세요."
        self.isLoading = false
      }
      NotificationCenter.post(.section(.sectionCRUDFailed))
    }
  }

  // MARK: 섹션 삭제 메서드 (하위 track, video, storage 파일도 함께 삭제)
  func deleteSection(
    tracksId: String,
    section: Section
  ) async throws {
    
    await MainActor.run {
      self.isLoading = true
    }
    
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
        self.isLoading = false
      }
    } catch {
      await MainActor.run {
        self.isLoading = false
      }
      throw SectionEditError.deleteError
    }
  }
}

private extension SectionEditViewModel {
  func createSection(
    tracksId: String,
    section: Section,
    updateSection: Section
  ) async throws {
    
    do {
      let strategy: WriteStrategy = self.isNewSection ? .create : .update
      try await store.createToSubcollection(
        updateSection,
        under: .tracks,
        parentId: tracksId,
        subCollection: .section,
        strategy: strategy
      )
    } catch {
      throw isNewSection ? SectionEditError.createError : SectionEditError.updateError
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
