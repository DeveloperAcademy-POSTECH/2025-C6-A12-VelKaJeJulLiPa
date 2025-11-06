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
  let sectionId: String
  
  init(
    sections: [Section],
    tracksId: String,
    trackName: String,
    sectionId: String
  ) {
    self._vm = State(initialValue: SectionEditViewModel(sections: sections))
    self.tracksId = tracksId
    self.trackName = trackName
    self.sectionId = sectionId
  }
  
  
  var body: some View {
    VStack {
      customHeader
      text
      Spacer().frame(height: 15)
      listView
    }
    .toolbar(.hidden, for: .tabBar)
    .padding(.horizontal, 16)
    .background(Color.white) // FIXME: 다크모드 배경색 명시
    .safeAreaInset(edge: .bottom) {
      Group {
        if vm.editingSectionid == nil {
          addButton
        } else {
          confirmButton
        }
      }
      .padding(.horizontal, 16)
    }
  }
  
  private var customHeader: some View { // FIXME: 컬러 폰트 수정
    HStack(alignment: .top, spacing: 16) {
      Button {
        router.pop()
      } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(.black)
      }
      VStack(alignment: .leading, spacing: 4) {
        Text("섹션 관리")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(.black) // FIXME: 다크모드 컬러 명시
        Text(trackName)
          .font(.system(size: 13))
          .foregroundStyle(.black) // FIXME: 다크모드 컬러 명시
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
        .foregroundStyle(Color.gray.opacity(0.8)) // FIXME: 컬러 수정
      Spacer()
    }
  }
  
  private var listView: some View {
    ScrollView {
      ForEach(vm.sections, id: \.sectionId) { section in
        SectionEditRow(
          tracksId: tracksId,
          section: section,
          isEditing: vm.editingSectionid == section.sectionId,
          onEditStart: { vm.startEdit(section: section) },
          sheetAction: {
            Task {
              await vm.deleteSection(tracksId: tracksId, section: section)
              SectionUpdateManager.shared.onSectionDeleted?(section.sectionId)
            }
          },
          editText: $vm.editText
        )
        .disabled(section.sectionId == sectionId)
        .opacity(section.sectionId == sectionId ? 0.5 : 1.0)
      }
    }
  }
  // 평상시 버튼
  private var addButton: some View {
    ActionButton(
      title: "섹션 추가하기",
      color: Color.blue,
      height: 47,
      action: { vm.addNewSection() }
    )
  }
  
  private var confirmButton: some View {
    RoundedRectangle(cornerRadius: 5)
      .fill((!vm.editText.isEmpty && vm.editText != "일반") ? Color.blue : Color.gray.opacity(0.5)) // FIXME: 컬러 수정
      .frame(maxWidth: .infinity)
      .frame(height: 47)
      .overlay {
        Text("확인")
          .font(Font.system(size: 16, weight: .medium)) // FIXME: - 폰트 수정
          .foregroundStyle(Color.white) // FIXME: - 컬러 수정
      }
      .onTapGesture {
        if !vm.editText.isEmpty && vm.editText != "일반" {
          if let sectionId = vm.editingSectionid,
             let section = vm.sections.first(where: { $0.sectionId == sectionId }) {
            Task {
              await vm.updateSection(tracksId: tracksId, section: section)
              if vm.isNewSection {
                // 새 섹션 추가
                SectionUpdateManager.shared.onSectionAdded?(section)
              } else {
                // 기존 섹션 수정
                SectionUpdateManager.shared.onSectionUpdated?(section.sectionId, vm.editText)
              }
            }
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
      trackName: "벨코의 리치맨",
      sectionId: ""
    )
  }
  .environmentObject(NavigationRouter())
}
