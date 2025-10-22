//
//  SectionSelectView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/20/25.
//

import SwiftUI

struct SectionSelectView: View {
  let section: [Section]
  let sectionId: String
  let track: Track
  let tracksId: String
  
  @State private var vm: SectionSelectViewModel = .init()
  @State private var selectedSectionId: String
  
  init(
    section: [Section],
    sectionId: String,
    track: Track,
    tracksId: String
  ) {
    self.section = section
    self.sectionId = sectionId
    self.track = track
    self.tracksId = tracksId
    _selectedSectionId = State(initialValue: sectionId)
  }
  
  var body: some View {
    ScrollView {
      ForEach(section, id: \.sectionId) { section in
        SectionSelectRow(
          section: section,
          isSelected: selectedSectionId == section.sectionId
        )
        .onTapGesture {
          if selectedSectionId == section.sectionId {
            selectedSectionId = ""
          } else {
            selectedSectionId = section.sectionId
          }
        }
      }
    }
    .padding(.horizontal, 16)
    .toolbar {
      ToolbarLeadingBackButton(icon: .xmark)
      ToolbarCenterTitle(text: "섹션 선택")
    }
    .safeAreaInset(edge: .bottom) {
      confirmButton
        .padding(.horizontal, 16)
    }
  }
  
  private var confirmButton: some View {
    ActionButton(
      title: "영상 이동하기",
      color:
        selectedSectionId == sectionId ? Color.blue.opacity(0.3) : Color.blue, // FIXME: 컬러 수정
      height: 47,
      isEnabled: selectedSectionId != sectionId,
      action: {
        Task {
          await vm.updateTrack(
            track: track,
            newSectionId: selectedSectionId,
            tracksId: tracksId,
            oldSectionId: sectionId
          )
        }
      }
    )
  }
}

#Preview {
  @Previewable @State var vm: SectionEditViewModel = .preview
  NavigationStack {
    SectionSelectView(
      section: vm.sections,
      sectionId: "",
      track: Track(
        trackId: "",
        videoId: "",
        sectionId: ""
      ),
      tracksId: ""
    )
  }
}
