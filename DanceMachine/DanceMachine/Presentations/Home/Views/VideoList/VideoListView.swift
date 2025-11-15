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
  
  @State private var showDeleteToast: Bool = false
  @State private var showEditToast: Bool = false
  @State private var showEditVideoTitleToast: Bool = false
  @State private var showCreateReportSuccessToast: Bool = false

  @State private var pickerViewModel = VideoPickerViewModel()

  init(
    vm: VideoListViewModel = .init(),
    tracksId: String,
    sectionId: String,
    trackName: String
  ) {
    self.vm = vm
    self.tracksId = tracksId
    self.sectionId = sectionId
    self.trackName = trackName
  }
  
  let tracksId: String
  let sectionId: String
  let trackName: String
  
  var body: some View {
    VStack(spacing: 0) {
      if vm.filteredVideos.isEmpty && vm.isLoading != true && !pickerViewModel.isUploading {
        emptyView
      } else {
        listView
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.backgroundNormal)
    .safeAreaInset(edge: .top, content: {
      sectionView
    })
    .safeAreaInset(edge: .bottom, content: {
      uploadButton
        .background(
          ZStack {
            // 2. 그 위에 그라데이션 (맨 앞)
            Color.black.opacity(0.1)
              .blur(radius: 10)
            
            LinearGradient(
              colors: [
                Color.clear,
                Color.black.opacity(0.4),
                Color.black.opacity(0.7),
                Color.black.opacity(0.9),
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          }
            .ignoresSafeArea(edges: .bottom)
        )
      
    })
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarLeadingBackButton(icon: .chevron)
      ToolbarCenterTitle(text: trackName)
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
      isPresented: $showDeleteToast,
      duration: 2,
      position: .bottom,
      bottomPadding: 63,
      content: {
        ToastView(
          text: "동영상이 삭제되었습니다.",
          icon: .check
        )
      }
    )
    .toast(
      isPresented: $showEditToast,
      duration: 2,
      position: .bottom,
      bottomPadding: 63,
      content: {
        ToastView(text: "영상이 이동되었습니다.", icon: .check)
      }
    )
    .toast(
      isPresented: $showEditVideoTitleToast,
      duration: 2,
      position: .bottom,
      bottomPadding: 63,
      content: {
        ToastView(text: "영상 이름이 수정되었습니다.", icon: .check)
      }
    )
    .toast(
      isPresented: $showCreateReportSuccessToast,
      duration: 3,
      position: .bottom,
      bottomPadding: 63, // FIXME: 신고하기 - 하단 공백 조정 필요
      content: {
        ToastView(text: "신고가 접수되었습니다.\n조치사항은 이메일로 안내해드리겠습니다.", icon: .check)
      }
    )
    // MARK: 영상 삭제 토스트 리시버
    .onReceive(NotificationCenter.default.publisher(for: .showDeleteToast)) { _ in
      self.showDeleteToast = true
    }
    // MARK: 영상 이름 수정 토스트 리시버
    .onReceive(NotificationCenter.default.publisher(for: .showEditVideoTitleToast, object: nil)) { _ in
      self.showEditVideoTitleToast = true
    }
    // MARK: 영상 섹션 이동 토스트 리시버
    .onReceive(NotificationCenter.default.publisher(for: .showEditToast)) { _ in
      self.showEditToast = true
    }
    // MARK: 신고 완료 토스트 리시버
    .onReceive(NotificationCenter.default.publisher(for: .showCreateReportSuccessToast)) { notification in
      if let toastViewName = notification.userInfo?["toastViewName"] as? ReportToastReceiveViewType,
         toastViewName == .videoListView {
        showCreateReportSuccessToast = true
      }
    }
    .overlay(alignment: .center) {
      if vm.showPermissionModal {
        PhotoLibraryPermissionView(
          onOpenSettigns: { vm.openSettings() },
          action: { vm.showPermissionModal = false }
        )
      }
    }
  }
    
    private var uploadButton: some View {
      HStack {
        if isScrollDown {
          Spacer()
        }

        Button {
          Task {
            await vm.requestPermissionAndFetch()
          }
        } label: {
          
            // 작은 버튼 (원형)
            if isScrollDown {
              Image(systemName: "video.fill.badge.plus")
                .font(.system(size: 22))
                .foregroundStyle(.labelStrong)
//                .transition(.opacity)
                .padding(.vertical, 14)
            }
            // 큰 버튼 (직사각형)
            if !isScrollDown {
              Text("동영상 업로드")
                .font(.headline1Medium)
                .foregroundStyle(.labelStrong)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
//                .transition(.opacity)
            }
        }
        .uploadGlassButton(isScrollDown: isScrollDown)
//        .frame(maxWidth: isScrollDown ? nil : .infinity)
        .shadow(radius: 5)
      }
      .padding(.horizontal, 16)
      .animation(.spring(response: 0.4, dampingFraction: 0.9), value: isScrollDown)
    }
    
    private var emptyView: some View {
      GeometryReader { geometry in
        VStack {
          Image(systemName: "movieclapper.fill")
            .font(.system(size: 75))
            .foregroundStyle(.labelAssitive)

          Spacer().frame(height: 25)

          Text("비디오가 없습니다.")
            .font(.caption1Medium)
            .foregroundStyle(.labelAssitive)
        }
        .frame(maxWidth: .infinity)
        .position(
          x: geometry.size.width / 2,
          y: geometry.size.height / 2
        )
      }
    }
    // MARK: 영상 그리드 뷰
    private var listView: some View {
      GeometryReader { g in
        let horizontalPadding: CGFloat = 16
        let spacing: CGFloat = 16
        let columns = 2
        
        let totalSpacing = spacing * CGFloat(columns - 1)
        let availableWidth = g.size.width - (horizontalPadding * 2) - totalSpacing
        let itemSize = availableWidth / CGFloat(columns)
        
        ScrollView {
          VideoGrid(
            size: itemSize,
            columns: columns,
            spacing: spacing,
            tracksId: tracksId,
            videos: vm.filteredVideos,
            track: vm.track,
            section: vm.section,
            pickerViewModel: pickerViewModel,
            vm: $vm
          )
          .padding(.horizontal, horizontalPadding)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
          geometry.contentOffset.y
        } action: { oldValue, newValue in
          withAnimation(.spring()) {
            isScrollDown = newValue > 50
          }
        }
        .refreshable {
          await vm.forceRefreshFromServer(tracksId: tracksId)
        }
        .background(.backgroundNormal)
      }
    }
    
    
    // MARK: 섹션 칩 뷰
    private var sectionView: some View {
      ScrollView(.horizontal, showsIndicators: false) {
        //      GlassEffectContainer {
        HStack {
          SectionChipIcon(
            vm: $vm,
            action: {
              router.push(
                to: .video(
                  .section(
                    section: vm.section,
                    tracksId: tracksId,
                    trackName: trackName,
                    sectionId: sectionId
                  )
                )
              )
            }
          )
          if vm.isLoading {
            ForEach(0..<5, id: \.self) { _ in
              SkeletonChipVIew()
            }
          } else {
            ForEach(vm.section, id: \.sectionId) { section in
              CustomSectionChip(
                vm: $vm,
                action: { vm.selectedSection = section },
                title: section.sectionTitle,
                id: section.sectionId
              )
            }
          }
        }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .environment(\.colorScheme, .light)
      }
    }
  



#Preview {
  @Previewable @State var vm: VideoListViewModel = .preview
  NavigationStack {
    VideoListView(vm: vm, tracksId: "", sectionId: "", trackName: "벨코의 리치맨")
  }
  .environmentObject(MainRouter())
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}
