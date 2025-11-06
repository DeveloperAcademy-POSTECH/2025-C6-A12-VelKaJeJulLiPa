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
    .overlay { if vm.isLoading { LoadingView() }}
    .safeAreaInset(edge: .top, content: {
      sectionView
    })
    .safeAreaInset(edge: .bottom, content: {
      uploadButtons
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
    // MARK: 글래스 모피즘 사용하여 플로팅 버튼을 rootView에서 관리할때 쓰는 리시버
    .onReceive(
      NotificationCenter.default.publisher(
        for: .showVideoPicker)
    ) { _ in
          self.showCustomPicker = true
        }
    // MARK: 비디오 업로드 했을때 리시버
    .onReceive(
      NotificationCenter.default.publisher(for: .videoUpload)
    ) { _ in
      Task {
        await vm.loadFromServer(tracksId: tracksId)
      }
    }
    // MARK: 영상 이동 토스트 리시버
    .onReceive(NotificationCenter.default.publisher(for: .showEditToast)) { _ in
      self.showEditToast = true
    }
    // MARK: 영상 삭제 토스트 리시버
    .onReceive(NotificationCenter.default.publisher(for: .showDeleteToast)) { _ in
      self.showDeleteToast = true
    }
    // MARK: 영상 이름 수정 토스트 리시버
    .onReceive(NotificationCenter.default.publisher(for: .showEditVideoTitleToast, object: nil)) { _ in
      self.showEditVideoTitleToast = true
    }
}
  
  private var uploadButtons: some View {
    Button {
      self.showCustomPicker = true
    } label: {
      Text("동영상 업로드")
        .font(.headline1Medium)
        .foregroundStyle(.labelStrong)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .uploadGlassButton()
    }
    .padding(.horizontal, 16)
    .environment(\.colorScheme, .light)
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
          .onTapGesture {
            // TODO: 비디오 플레이 화면 네비게이션 연결
            print("비디오 클릭")
          }
        }
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
//        .padding([.horizontal, .vertical], 16)
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
  .environmentObject(NavigationRouter())
}
