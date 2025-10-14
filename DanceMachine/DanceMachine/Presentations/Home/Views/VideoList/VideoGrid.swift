//
//  VideoGrid.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/10/25.
//

import SwiftUI

struct VideoGrid: View {
  let size: CGFloat
  let columns: Int
  let spacing: CGFloat
  
  @Binding var videos: [Video]
  
  var body: some View {
    LazyVGrid(
      columns: Array(
        repeating: GridItem(.flexible()),
        count: columns
      ),
      spacing: spacing
    ) {
#if DEBUG
      if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
        ForEach(0..<10, id: \.self) { _ in
          cell
        }
      } else {
        ForEach(videos, id: \.videoId) { video in
          GridCell(
            size: size,
            title: video.videoTitle,
            duration: video.videoDuration,
            uploadDate: video.createdAt ?? Date()
          )
        }
      }
#else
      ForEach(videos, id: \.videoId) { video in
        GridCell(
          size: size,
          title: video.videoTitle,
          duration: video.videoDuration,
          uploadDate: video.createdAt ?? Date()
        )
      }
#endif
    }
  }
  // 디자인 확인용
  private var cell: some View {
    Rectangle()
      .fill(Color.gray.opacity(0.5))
      .frame(width: size, height: size)
      .overlay {
        VStack {
          Text("동영상 썸네일")
          Text("동영상 제목")
          HStack {
            Text("동영상 길이")
            Text("올린 날짜")
          }
          .padding(.horizontal, 5)
        }
      }
  }
}

#Preview {
  VideoGrid(
    size: 168,
    columns: 2,
    spacing: 16,
    videos: .constant([])
  )
}
