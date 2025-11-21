//
//  VideoListView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/4/25.
//

import SwiftUI
import Photos

struct VideoListView: View {
  @EnvironmentObject private var router: MainRouter
  
  @State var vm: VideoListViewModel
  
  @State private var isScrollDown: Bool = false
  //  @State private var isRefreshing: Bool = false
  
  @State private var showDeleteToast: Bool = false
  @State private var showEditToast: Bool = false
  @State private var showEditVideoTitleToast: Bool = false
  @State private var showCreateReportSuccessToast: Bool = false
  @State private var showVideoEditFailedToast: Bool = false
  
  @State private var pickerViewModel = VideoPickerViewModel()
  
  init(
    vm: VideoListViewModel = .init(),
    tracksId: String,
    sectionId: String,
    trackName: String,
    onBackButtonTap: (() -> Void)? = nil
  ) {
    self.vm = vm
    self.tracksId = tracksId
    self.sectionId = sectionId
    self.trackName = trackName
    self.onBackButtonTap = onBackButtonTap
  }

  let tracksId: String
  let sectionId: String
  let trackName: String
  let onBackButtonTap: (() -> Void)?
  
  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        if vm.showErrorView {
          errorView(g: geometry)
        } else if vm.filteredVideos.isEmpty && vm.isLoading != true && !pickerViewModel.isUploading {
          emptyContent(g: geometry)
        } else {
          VideoListContent(
            geometry: geometry,
            tracksId: tracksId,
            videos: vm.filteredVideos,
            track: vm.track,
            section: vm.section,
            pickerViewModel: pickerViewModel,
            vm: $vm
          )
        }
      }
      .scrollDisabled(vm.isLoading && !vm.isRefreshing)
      .refreshable {
        await vm.refresh(tracksId: tracksId)
      }
      .background(.backgroundNormal)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.backgroundNormal)
    .safeAreaInset(edge: .top) {
      SectionContent(
        vm: $vm,
        tracksId: tracksId,
        trackName: trackName,
        sectionId: sectionId
      )
    }
    .navigationBarTitleDisplayMode(.inline)
//    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarLeadingBackButton(icon: .chevron, action: onBackButtonTap)
      ToolbarCenterTitle(text: trackName)
      ToolbarUploadButton {
        Task {
          await vm.requestPermissionAndFetch()
        }
      }
    }
    .task {
      await vm.loadFromServer(tracksId: tracksId)
    }
    .onChange(of: pickerViewModel.lastUploadedVideo) { _, newValue in
      guard let video = newValue, let track = pickerViewModel.lastUploadedTrack else { return }
      Task {
        await vm.addNewVideo(video: video, track: track, traksId: tracksId)
        await MainActor.run {
          pickerViewModel.lastUploadedVideo = nil
          pickerViewModel.lastUploadedTrack = nil
        }
      }
    }
    // MARK: 영상 피커 시트
    .sheet(isPresented: $vm.showCustomPicker) {
      VideoPickerView(
        pickerViewModel: pickerViewModel,
        tracksId: tracksId,
        sectionId: vm.selectedSection?.sectionId ?? sectionId,
        trackName: trackName
      )
    }
    .toast(
      isPresented: $vm.showVideoTitleEditErrorToast,
      duration: 2,
      position: .bottom,
      bottomPadding: 16,
      content: {
        ToastView(
          text: vm.errorMsg ?? "동영상 이름 수정을 실패했습니다.",
          icon: .warning
        )
      }
    )
    .toast(
      isPresented: $vm.showDeleteErrorToast,
      duration: 2,
      position: .bottom,
      bottomPadding: 16,
      content: {
        ToastView(
          text: vm.errorMsg ?? "동영상 삭제를 실패했습니다.",
          icon: .warning
        )
      }
    )
    .notificationToast(
      isPresented: $showVideoEditFailedToast,
      text: "동영상 이동을 실패했습니다.",
      icon: .warning,
      for: .video(.videoEditFailed),
      bottomPadding: 16
    )
    .notificationToast(
      isPresented: $showDeleteToast,
      text: "동영상이 삭제되었습니다.",
      icon: .check,
      for: .video(.videoDelete),
      bottomPadding: 16
    )
    .notificationToast(
      isPresented: $showEditVideoTitleToast,
      text: "영상 이름이 수정되었습니다.",
      icon: .check,
      for: .video(.videoTitleEdit),
      bottomPadding: 16
    )
    .notificationToast(
      isPresented: $showEditToast,
      text: "영상이 이동되었습니다.",
      icon: .check,
      for: .video(.videoEdit),
      bottomPadding: 16
    )
    .notificationToast(
      isPresented: $showCreateReportSuccessToast,
      text: "신고가 접수되었습니다.\n조치사항은 이메일로 안내해드리겠습니다.",
      icon: .check,
      for: .toast(.reportSuccess),
      bottomPadding: 16,
      targetViewType: .videoListView
    )
    .overlay(alignment: .center) {
      if vm.showPermissionModal {
        PhotoLibraryPermissionView(
          onOpenSettigns: { vm.openSettings() },
          action: { vm.showPermissionModal = false }
        )
      }
    }
  }
  
  private func errorView(g: GeometryProxy) -> some View {
    ErrorStateView(
      message: "동영상 불러오기를 실패했습니다.\n네트워크를 확인해 주세요.",
      isAnimating: true,
      onRetry: {
        Task {
          await vm.refresh(tracksId: tracksId)
        }
      }
    )
    .frame(width: g.size.width, height: g.size.height)
    .position(
      x: g.size.width / 2,
      y: g.size.height / 2 - 40
    )
  }
  
  private func emptyContent(g: GeometryProxy) -> some View {
    Button {
      Task { await vm.requestPermissionAndFetch() }
    } label: {
      VStack(spacing: 24) {
        Image(systemName: "video.fill.badge.plus")
          .symbolRenderingMode(.hierarchical)
          .font(.system(size: 75))
          .foregroundStyle(.secondaryNormal)
        Text("비디오를 추가해 보세요.")
          .font(.headline2Medium)
          .foregroundStyle(.secondaryAssitive)
      }
    }
    .buttonStyle(.plain)
    .frame(width: g.size.width, height: g.size.height)
    .position(
      x: g.size.width / 2,
      y: g.size.height / 2 - 40
    )
  }
}

#Preview {
  @Previewable @State var vm: VideoListViewModel = .preview
  NavigationStack {
    VideoListView(vm: vm, tracksId: "", sectionId: "", trackName: "벨코의 리치맨")
  }
  .environmentObject(MainRouter())
}
