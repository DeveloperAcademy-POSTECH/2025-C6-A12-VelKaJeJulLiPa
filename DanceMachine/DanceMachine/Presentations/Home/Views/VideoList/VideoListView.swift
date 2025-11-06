//
//  VideoListView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/4/25.
//

import SwiftUI

struct VideoListView: View {
  @EnvironmentObject private var router: MainRouter
  
  @State private var showCustomPicker: Bool = false
  
  @State var vm: VideoListViewModel
  
  @State private var isScrollDown: Bool = false
  
  @State private var showDeleteToast: Bool = false
  @State private var showEditToast: Bool = false
  @State private var showEditVideoTitleToast: Bool = false
  
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
      if vm.videos.isEmpty && vm.isLoading != true {
        emptyView
        //        uploadButtons
      } else {
        listView
        //        uploadButtons
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
    // MARK: 영상 삭제 토스트 리시버
    .onReceive(NotificationCenter.default.publisher(for: .showDeleteToast)) { _ in
      self.showDeleteToast = true
    }
    // MARK: 영상 이름 수정 토스트 리시버
    .onReceive(NotificationCenter.default.publisher(for: .showEditVideoTitleToast, object: nil)) { _ in
      self.showEditVideoTitleToast = true
    }
  }
    
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
            .uploadGlassButton()
            .environment(\.colorScheme, .light)
        )
        .shadow(radius: 5)
      }
      .padding(.horizontal, 16)
      .animation(.spring(response: 0.4, dampingFraction: 0.9), value: isScrollDown)
    }
    
    private var emptyView: some View {
      VStack {
        Spacer()
        Image(systemName: "movieclapper.fill")
          .font(.system(size: 75))
          .foregroundStyle(.labelAssitive)
        
        Spacer().frame(height: 25)
        
        Text("비디오가 없습니다.")
          .font(.caption1Medium)
          .foregroundStyle(.labelAssitive)
        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .offset(y: -40)
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
