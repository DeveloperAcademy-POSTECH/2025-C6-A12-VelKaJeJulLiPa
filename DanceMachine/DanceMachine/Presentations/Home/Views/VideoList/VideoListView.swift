//
//  VideoListView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/4/25.
//

import SwiftUI

struct VideoListView: View {
  @EnvironmentObject private var router: NavigationRouter
  
  @State private var showCustomPicker: Bool = false

  @State var vm: VideoListViewModel

  @State private var isScrollDown: Bool = false
  
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
    ZStack {
      if vm.videos.isEmpty && !vm.isLoading && !VideoProgressManager.shared.isUploading {
        emptyView
      } else {
        listView
      }
    }
    .background(Color.white) // FIXME: 배경색 지정 (다크모드)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
      VideoProgressManager.shared.onUploadComplete = { video, track in
        Task {
          await vm.addNewVideo(video: video, track: track, traksId: tracksId)
        }
      }
      // 섹션 업데이트 콜백 설정
      SectionUpdateManager.shared.onSectionAdded = { section in
        vm.addSection(section)
      }
      SectionUpdateManager.shared.onSectionDeleted = { sectionId in
        vm.removeSectionWithVideos(sectionId: sectionId)
      }
      SectionUpdateManager.shared.onSectionUpdated = { sectionId, newTitle in
        vm.updateSectionTitle(sectionId: sectionId, newTitle: newTitle)
      }
      SectionUpdateManager.shared.onTrackMoved = { trackId, newSectionId in
        vm.moveTrack(trackId: trackId, toSectionId: newSectionId)
      }
    }
    // MARK: 영상 피커 시트
      .sheet(isPresented: $showCustomPicker) {
        VideoPickerView(
          tracksId: tracksId,
          sectionId: vm.selectedSection?.sectionId ?? sectionId
        )
      }
    // MARK: 비디오 업로드 했을때 리시버
      .onReceive(
        NotificationCenter.default.publisher(for: .videoUpload)
      ) { _ in
        Task {
          await vm.loadFromServer(tracksId: tracksId)
        }
      }
  }
  
  //  private var glassButton: some View {
  //    GlassEffectContainer {
  //      HStack(spacing: 20) {
  //        homeButton
  //        uploadButton
  //      }
  //    }
  //    .padding(.horizontal, 16)
  //  }
  
  //  private var homeButton: some View {
  //    Button {
  //      // TODO: 여긴 뭐지?
  //    } label: {
  //      Image(systemName: "house.fill")
  //        .foregroundStyle(Color.purple.opacity(0.8))
  //    }
  //    .frame(width: 47, height: 47)
  //    .glassEffect(.clear.interactive(), in: .circle)
  //  }
  
  private var uploadButton: some View {
    HStack {
      if isScrollDown {
        Spacer()
      }

      Button {
        self.showCustomPicker = true
      } label: {
        ZStack {
          // 작은 버튼 (원형)
          if isScrollDown {
            Image(systemName: "plus")
              .font(.system(size: 22))
              .foregroundStyle(.white)
              .transition(.opacity)
          }
          // 큰 버튼 (직사각형)
          if !isScrollDown {
            Text("동영상 업로드")
              .font(.system(size: 17))
              .foregroundStyle(Color.white)
              .frame(maxWidth: .infinity)
              .transition(.opacity)
          }
        }
        .padding(.horizontal, isScrollDown ? 12 : 20)
        .padding(.vertical, isScrollDown ? 12 : 14)
        .frame(maxWidth: isScrollDown ? nil : .infinity)
      }
      .background(
        RoundedRectangle(cornerRadius: isScrollDown ? 24 : 1000)
          .fill(Color.blue)
      )
      .shadow(radius: 5)
    }
    .padding(.horizontal, 16)
    .animation(.spring(response: 0.4, dampingFraction: 0.9), value: isScrollDown)
  }
  
  private var emptyView: some View {
    VStack {
      Spacer()
      HStack {
        Image(systemName: "folder.badge.plus")
          .foregroundStyle(Color.black) // FIXME: - 컬러 수정
        
        Text("폴더 버튼을 눌러서 파트를 추가하세요")
          .font(.system(size: 18, weight: .semibold)) // FIXME: - 폰트 수정
          .foregroundStyle(Color.black) // FIXME: - 컬러 수정
      }
      Spacer()
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
      .background(Color.white) // FIXME: 배경색 지정 (다크모드)
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
      .padding(.horizontal, 1) // FIXME: 여백 없으면 캡슐이 짤리는 현상 있음
      .padding(.vertical, 1) // FIXME: 여백 없으면 캡슐이 짤리는 현상 있음
      //      }
    }
    .padding(.horizontal, 16)
  }
}


#Preview {
  @Previewable @State var vm: VideoListViewModel = .preview
  NavigationStack {
    VideoListView(vm: vm, tracksId: "", sectionId: "", trackName: "벨코의 리치맨")
  }
  .environmentObject(NavigationRouter())
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}
