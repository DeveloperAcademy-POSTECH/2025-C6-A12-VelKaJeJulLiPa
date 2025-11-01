//
//  VideoGrid.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/10/25.
//

import SwiftUI

struct VideoGrid: View {
  @EnvironmentObject private var router: NavigationRouter
  
  let size: CGFloat
  let columns: Int
  let spacing: CGFloat
  let tracksId: String
  
  let videos: [Video]
  let track: [Track]
  let section: [Section]
  
  @State private var selectedVideo: Video?
  @State private var selectedTrack: Track? // 섹션 이동
  @State private var showDeleteAlert: Bool = false // 삭제
  @Binding var vm: VideoListViewModel
  
  var body: some View {
    LazyVGrid(
      columns: Array(
        repeating: GridItem(.fixed(size), spacing: spacing),
        count: columns
      ),
      spacing: spacing
    ) {
      //#if DEBUG
      //      if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
      //        ForEach(0..<10, id: \.self) { _ in
      //          cell
      //        }
      //      } else {
      //        ForEach(videos, id: \.videoId) { video in
      //          if let track = track.first(where: { $0.videoId == video.videoId.uuidString }) {
      //            GridCell(
      //              size: size,
      //              thumbnailURL: video.thumbnailURL,
      //              title: video.videoTitle,
      //              duration: video.videoDuration,
      //              uploadDate: video.createdAt ?? Date(),
      //              editAction: {
      //                self.selectedTrack = track
      //              },
      //              deleteAction: {
      //                self.selectedVideo = video
      //                print("\(video.videoId)모달 선택")
      //              },
      //              videoAction: {
      //                router.push(
      //                  to: .video(
      //                    .play(
      //                      videoId: video.videoId.uuidString,
      //                      videoTitle: video.videoTitle,
      //                      videoURL: video.videoURL
      //                    )
      //                  )
      //                )
      //              }
      //            )
      //          }
      //        }
      //      }
      //#else
      ForEach(videos, id: \.videoId) { video in
        if let track = track.first(where: { $0.videoId == video.videoId.uuidString }) {
          GridCell(
            size: size,
            thumbnailURL: video.thumbnailURL,
            title: video.videoTitle,
            duration: video.videoDuration,
            uploadDate: video.createdAt ?? Date(),
            editAction: {
              self.selectedTrack = track
            },
            deleteAction: {
              self.selectedVideo = video
              self.showDeleteAlert = true
              print("\(video.videoId)모달 선택")
            },
            videoAction: {
              router.push(
                to: .video(
                  .play(
                    videoId: video.videoId.uuidString,
                    videoTitle: video.videoTitle,
                    videoURL: video.videoURL,
                  )
                )
              )
            }
          )
          .alert(
            "\(selectedVideo?.videoTitle ?? "영상")을/를 삭제하시겠어요?",
            isPresented: $showDeleteAlert) {
              Button("취소", role: .cancel) { }
              Button("삭제", role: .destructive) {
                Task {
                  await vm.deleteVideo(
                    video: video,
                    tracksId: tracksId
                  )
                }
              }
            } message: {
              Text("삭제하면 복구할 수 없습니다.")
            }
          
        }
      }
      //#endif
    }
    // MARK: 영상 섹션 이동 뷰
    .fullScreenCover(item: $selectedTrack) { track in
      NavigationStack {
        SectionSelectView(
          section: section,
          sectionId: track.sectionId,
          track: track,
          tracksId: tracksId
        )
      }
    }
  }
  // 디자인 확인용
  private var cell: some View {
    Rectangle()
      .fill(Color.gray.opacity(0.5))
      .frame(width: size, height: size * 1.2)
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

extension Track: Identifiable {
  var id: String { trackId }
}

extension Video: Identifiable {
  var id: String { videoId.uuidString }
}
//
#Preview {
  VideoGrid(
    size: 168,
    columns: 2,
    spacing: 16,
    tracksId: "",
    videos: [Video(
      videoId: UUID(),
      videoTitle: "벨코의 리치맨",
      videoDuration: 20.0,
      videoURL: "",
      thumbnailURL: ""
    )],
    track: [Track(
      trackId: "",
      videoId: "",
      sectionId: ""
    )],
    section: [Section(
      sectionId: "",
      sectionTitle: "22"
    )],
    vm: .constant(VideoListViewModel())
  )
}
