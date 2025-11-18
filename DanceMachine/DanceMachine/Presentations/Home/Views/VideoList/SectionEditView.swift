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
  @State private var showDeleteAlert: Bool = false
  @State private var sectionToDelete: Section? = nil

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
  
  var filteredSection: [Section] {
    vm.sections.filter { $0.sectionId != sectionId }
  }
  
  var body: some View {
    VStack(spacing: 0) {
      if filteredSection.isEmpty {
        emptyView
      } else {
        listView.padding(.top, 16)
      }
    }
    .onReceive(NotificationCenter.publisher(for: .section(.sectionEditWarning))) { _ in
      self.showToast = true
    }
    .onReceive(NotificationCenter.publisher(for: .section(.sectionCRUDFailed))) { _ in
      self.showCRUDToast = true
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .toolbar(.hidden, for: .tabBar)
    .padding(.horizontal, 16)
    .background(.backgroundNormal)
    .safeAreaInset(edge: .top, content: {
      text.padding(.horizontal, 16)
    })
    .safeAreaInset(edge: .bottom) {
      if !filteredSection.isEmpty {
        confirmButton
          .padding(.horizontal, 16)
      }
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
      .alert(
        "\(sectionToDelete?.sectionTitle ?? "파트")을/를 삭제하시겠어요?",
        isPresented: $showDeleteAlert
      ) {
        Button("취소", role: .cancel) {
          sectionToDelete = nil
        }
        Button("삭제", role: .destructive) {
          if let section = sectionToDelete {
            Task {
              await vm.deleteSection(tracksId: tracksId, section: section)
              sectionToDelete = nil
            }
          }
        }
      } message: {
        Text("삭제하면 복구할 수 없습니다.")
      }
  }
  
  private var emptyView: some View {
    GeometryReader { geometry in
      VStack {
        Button {
          vm.addNewSection()
        } label: {
          VStack(spacing: 24) {
            Image(.sectionAdd)
            Text("파트를 추가해보세요.")
              .font(.headline2Medium)
              .foregroundStyle(.secondaryAssitive)
          }
        }
      }
      .frame(maxWidth: .infinity)
      .position(
        x: geometry.size.width / 2,
        y: geometry.size.height / 2 - 32
      )
    }
  }
  
  private var text: some View {
    HStack {
      Text("파트 리스트")
        .font(.headline2Medium)
        .foregroundStyle(.labelAssitive)
      Spacer()
      Button {
        vm.addNewSection()
      } label: {
        HStack(spacing: 4) {
          Image(systemName: "plus")
            .font(.headline2SemiBold)
            .foregroundStyle(.secondaryNormal)
          Text("추가")
            .font(.headline2SemiBold)
            .foregroundStyle(.secondaryNormal)
        }
      }
    }
    .padding(.top, 32)
  }
  
  private var listView: some View {
    List {
      ForEach(filteredSection, id: \.sectionId) { section in
        SectionEditRow(
          tracksId: tracksId,
          section: section,
          isEditing: vm.editingSectionid == section.sectionId,
          onEditStart: { vm.startEdit(section: section) },
          onDeleteIfEmpty: {
            Task {
              await vm.deleteSection(tracksId: tracksId, section: section)
              vm.editingSectionid = nil
            }
          },
          editText: $vm.editText,
          showToast: $showToast
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
          Button(role: .destructive) {
            sectionToDelete = section
            showDeleteAlert = true
          } label: {
            Label("삭제", systemImage: "trash")
          }

          Button {
            vm.startEdit(section: section)
          } label: {
            Label("수정", systemImage: "pencil")
          }
          .tint(Color.fillAssitive)
        }
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
  }
  
  private var confirmButton: some View {
    RoundedRectangle(cornerRadius: 15)
      .fill(!vm.editText.isEmpty ? .secondaryStrong : .fillAssitive)
      .frame(maxWidth: .infinity)
      .frame(height: 47)
      .overlay {
        Text("확인")
          .font(.headline2Medium)
          .foregroundStyle(vm.editText.isEmpty ? .labelAssitive : .labelStrong)
      }
      .onTapGesture {
        if !vm.editText.isEmpty {
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
