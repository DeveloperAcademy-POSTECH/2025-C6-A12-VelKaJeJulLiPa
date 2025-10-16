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
    VStack {
      sectionView
      if vm.isLoading {
        Spacer().frame(maxWidth: .infinity)
        ProgressView()
        Spacer().frame(maxWidth: .infinity)
      } else if vm.videos.isEmpty {
        emptyView
      } else {
        listView
      }
      uploadButton
    }
    .task {
      await vm.loadFromServer(tracksId: tracksId)
    }
    .sheet(isPresented: $showCustomPicker) {
      VideoPickerView(tracksId: tracksId, sectionId: sectionId)
    }
    .toolbar {
      ToolbarLeadingBackButton(icon: .chevron)
      ToolbarCenterTitle(text: trackName)
    }
  }
  
  private var uploadButton: some View {
    Button {
      self.showCustomPicker = true
    } label: {
      Image(systemName: "plus.circle.fill")
        .resizable()
        .frame(width: 44, height: 44)
    }
  }
  
  private var emptyView: some View {
    VStack {
      Spacer()
      Text("업로드 된 영상이 없습니다.")
      Spacer()
    }
  }
  
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
          videos: .constant(vm.filteredVideos)
        )
        .onTapGesture {
          // TODO: 비디오 플레이 화면 네비게이션 연결
          print("비디오 클릭")
        }
      }
    }
  }
  
  private var sectionView: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack {
        SectionChipIcon(vm: $vm)
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
