//
//  VideoListView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/4/25.
//

import SwiftUI

struct VideoListView: View {
  @EnvironmentObject private var router: NavigationRouter
  @State private var videos: [Video] = []
  
  // MARK: 비디오 업로드 관련
  @State private var localVideoURL: URL? = nil
  
  @State private var videoTitle: String = ""
  @State private var videoDuration: Double = 0
  @State private var videoThumbnail: UIImage? = nil
  
  @State private var isUploading: Bool = false
  @State private var showCustomPicker: Bool = false
  
  var body: some View {
    listView
      .sheet(isPresented: $showCustomPicker) {
        VideoPickerView { url, thumbnail, duration in
          self.localVideoURL = url
          self.videoThumbnail = thumbnail
          self.videoDuration = duration
        }
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
      Text("업로드 된 영상이 없습니다.")
    }
  }
  
  private var listView: some View {
    GeometryReader { g in
      let spacing: CGFloat = 16
      let columns = 2
      let totalSpacing = spacing * CGFloat(columns - 1)
      let itemSize = min((g.size.width - totalSpacing) / CGFloat(columns), 168)
      ScrollView {
        VideoGrid(
          size: itemSize,
          columns: columns,
          spacing: spacing,
          videos: $videos
        )
        .onTapGesture {
          // TODO: 비디오 플레이 화면 네비게이션 연결
          print("비디오 클릭")
        }
      }
      .padding(.horizontal, 16)
    }
  }
  
  private func loadVideoFormServer() {
    // TODO: 서버에서 영상 조회
  }
}

#Preview {
  NavigationStack {
    VideoListView()
  }
  .environmentObject(NavigationRouter())
}
