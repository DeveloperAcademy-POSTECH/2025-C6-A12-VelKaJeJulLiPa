//
//  SectionEditView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/17/25.
//

import SwiftUI

struct SectionEditView: View {
  @EnvironmentObject private var router: MainRouter
  @State private var vm: SectionEditViewModel
  @State private var showToast: Bool = false
  @State private var showExitAlert: Bool = false

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
      text
      Spacer().frame(height: 15)
      listView
    }
    .onReceive(NotificationCenter.default.publisher(for: .showEditWarningToast, object: nil), perform: { _ in
      self.showToast = true
    })
    .padding(.top, 16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .toolbar(.hidden, for: .tabBar)
    .padding(.horizontal, 16)
    .background(.backgroundNormal)
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
    .toolbarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarLeadingBackButton(icon: .chevron) {
        if vm.isEditing {
          self.showExitAlert = true
        } else {
          router.pop()
        }
      }
      ToolbarItem(placement: .title) {
        VStack(alignment: .center) {
          Text("파트 관리")
            .font(.headline2SemiBold)
            .foregroundStyle(.labelStrong)
          Text("\(trackName)")
            .font(.caption1Medium)
            .foregroundStyle(.labelNormal)
        }
      }
    }
    .navigationBarBackButtonHidden(true)
    .toast(
      isPresented: $showToast,
      duration: 2,
      position: .bottom,
      bottomPadding: 63) {
        ToastView(text: "10자 미만으로 입력해주세요.", icon: .warning)
      }
      .unsavedChangesAlert(
        isPresented: $showExitAlert,
        onConfirm: { router.pop() }
      )
  }
  
  private var text: some View {
    HStack {
      Text("파트 리스트")
        .font(.headline2Medium)
        .foregroundStyle(.labelAssitive)
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
          onDeleteIfEmpty: {
            Task {
              await vm.deleteSection(tracksId: tracksId, section: section)
              vm.editingSectionid = nil
            }
          },
          editText: $vm.editText,
          showToast: $showToast
        )
        .disabled(section.sectionId == sectionId)
        .opacity(section.sectionId == sectionId ? 0.5 : 1.0)
      }
    }
  }
  // 평상시 버튼
  private var addButton: some View {
    ActionButton(
      title: "파트 추가하기",
      color: .secondaryStrong,
      height: 47,
      action: { vm.addNewSection() }
    )
    .padding(.bottom, 8)
  }
  
  private var confirmButton: some View {
    RoundedRectangle(cornerRadius: 5)
      .fill((!vm.editText.isEmpty && vm.editText != "일반") ? .secondaryStrong : .fillAssitive)
      .frame(maxWidth: .infinity)
      .frame(height: 47)
      .overlay {
        Text("확인")
          .font(.headline2Medium)
          .foregroundStyle(vm.editText.isEmpty ? .labelAssitive : .labelStrong)
      }
      .onTapGesture {
        if !vm.editText.isEmpty && vm.editText != "일반" {
          if let sectionId = vm.editingSectionid,
             let section = vm.sections.first(where: { $0.sectionId == sectionId }) {
            Task {
              await vm.updateSection(tracksId: tracksId, section: section)
            }
          }
        }
      }
      .padding(.bottom, 8)
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
  .environmentObject(MainRouter())
}
