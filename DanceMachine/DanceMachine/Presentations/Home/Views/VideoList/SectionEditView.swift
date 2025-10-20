//
//  SectionEditView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/17/25.
//

import SwiftUI

struct SectionEditView: View {
  @EnvironmentObject private var router: NavigationRouter
  @State private var vm: SectionEditViewModel
  
  let tracksId: String
  let trackName: String
  
  init(
    sections: [Section],
    tracksId: String,
    trackName: String
  ) {
    self._vm = State(initialValue: SectionEditViewModel(sections: sections))
    self.tracksId = tracksId
    self.trackName = trackName
  }
  
  
  var body: some View {
    VStack {
      customHeader
      text
      Spacer().frame(height: 15)
      listView
    }
    .padding(.horizontal, 16)
    .safeAreaInset(edge: .bottom) {
      Group {
        if vm.editingSectionid == nil {
          addButton
        } else {
          confirButtons
        }
      }
      .padding(.horizontal, 16)
    }
  }
  
  private var customHeader: some View {
    HStack(alignment: .top, spacing: 16) {
      Button {
        vm.notify(.sectionDidUpdate)
        router.pop()
      } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(.black)
      }
      VStack(alignment: .leading, spacing: 4) {
        Text("섹션 관리")
          .font(.system(size: 17, weight: .semibold))
        Text(trackName)
          .font(.system(size: 13))
          .foregroundStyle(.secondary)
      }
      .onTapGesture {
        router.pop()
      }
      Spacer()
    }
    .padding(.vertical, 12)
  }
  
  
  private var text: some View {
    HStack {
      Text("섹션 리스트")
        .font(Font.system(size: 14, weight: .semibold)) // FIXME: 폰트 수정
        .foregroundStyle(Color.gray.opacity(0.8))
      Spacer()
    }
  }
  
  private var listView: some View {
    ScrollView {
      ForEach(vm.sections, id: \.sectionId) { section in
        SectionEditRow(
          section: section,
          isEditing: vm.editingSectionid == section.sectionId,
          onEditStart: { vm.startEdit(section: section) },
          onDelete: {
            Task {
              await vm.deleteSection(tracksId: tracksId, section: section)
            }
          },
          editText: $vm.editText
        )
      }
    }
  }
  
  private var confirButtons: some View {
    RoundedRectangle(cornerRadius: 5)
      .fill(!vm.editText.isEmpty ? Color.blue : Color.gray.opacity(0.5))
      .frame(maxWidth: .infinity)
      .frame(height: 47)
      .overlay {
        Text("확인")
          .font(Font.system(size: 16, weight: .medium)) // FIXME: - 폰트 수정
          .foregroundStyle(Color.white) // FIXME: - 컬러 수정
      }
      .onTapGesture {
        if !vm.editText.isEmpty {
          if let sectionId = vm.editingSectionid,
             let section = vm.sections.first(where: { $0.sectionId == sectionId }) {
            Task { await vm.updateSection(tracksId: tracksId, section: section) }
          }
        }
      }
  }
}

#Preview {
  @Previewable @State var vm: SectionEditViewModel = .preview
  NavigationStack {
    SectionEditView(
      sections: vm.sections,
      tracksId: "",
      trackName: "벨코의 리치맨")
  }
  .environmentObject(NavigationRouter())
}
