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
    ZStack(alignment: .bottom) {
      if vm.videos.isEmpty && vm.isLoading != true {
        emptyView
      } else {
        listView
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.white) // FIXME: 배경색 지정 (다크모드)
    .overlay { if vm.isLoading { LoadingView() }}
    .safeAreaInset(edge: .top, content: {
      sectionView
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
    // MARK: 섹션 변경 감지 해서 업데이트하는 노티
    .onReceive(NotificationCenter.default.publisher(
      for: .sectionDidUpdate)) { _ in
        Task { await vm.loadFromServer(tracksId: tracksId) }
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
    Button {
      self.showCustomPicker = true
    } label: {
      Text("동영상 업로드")
        .font(.system(size: 17)) // FIXME: 폰트 수정
        .foregroundStyle(Color.white)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 47)
    .background(
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.blue) // FIXME: - 컬러수정
    )
    .padding(.horizontal, 16) // FIXME: - 패딩 수정
    .padding(.bottom, 8) // FIXME: - 패딩 수정
//    .glassEffect(
//      .clear.tint(Color.purple.opacity(0.7)).interactive(),
//      in: RoundedRectangle(cornerRadius: 1000)
//    )
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
          .onTapGesture {
            // TODO: 비디오 플레이 화면 네비게이션 연결
            print("비디오 클릭")
          }
        }
        .background(Color.white) // FIXME: 배경색 지정 (다크모드)
      }
    .overlay { if vm.filteredVideos.isEmpty && vm.isLoading == false { emptyView }}
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
          ForEach(vm.section, id: \.sectionId) { section in
            CustomSectionChip(
              vm: $vm,
              action: { vm.selectedSection = section },
              title: section.sectionTitle,
              id: section.sectionId
            )
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
