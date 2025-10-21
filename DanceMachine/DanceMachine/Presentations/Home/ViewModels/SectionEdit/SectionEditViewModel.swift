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
  
  var sections: [Section]
  var editingSectionid: String? = nil
  var editText: String = ""
  
  var isNewSection: Bool = false // 수정모드와 추가모드 플래그
  
  init(sections: [Section]) {
    self.sections = sections
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
  // MARK: 노티 메서드
  func notify(_ name: Foundation.Notification.Name) {
    NotificationCenter.default.post(name: name, object: nil)
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
      
      await MainActor.run {
        sections.append(newSection)
      }
    } catch { // TODO: 에러 처리
      print("섹션 추가 실패: \(error)")
    }
  }
  // MARK: 섹션 삭제 메서드
  func deleteSection(
    tracksId: String,
    section: Section
  ) async {
    do {
      try await store.deleteFromSubcollection(
        under: .tracks,
        parentId: tracksId,
        subCollection: .section,
        target: section.sectionId
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
