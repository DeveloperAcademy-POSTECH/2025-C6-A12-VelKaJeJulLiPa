//
//  VideoGrid.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/10/25.
//

import SwiftUI

struct VideoGrid: View {
  @EnvironmentObject private var router: MainRouter

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
  @State private var showEditVideoTitle: Video?
  @State private var progressManager = VideoProgressManager.shared
  @Binding var vm: VideoListViewModel
  
  var body: some View {
    LazyVGrid(
      columns: Array(
        repeating: GridItem(.fixed(size), spacing: spacing),
        count: columns
      ),
      spacing: spacing
    ) {
      if progressManager.isUploading {
        UploadProgressCard(
          cardSize: size,
          progress: progressManager.uploadProgress
        )
      }
      if vm.isLoading {
        ForEach(0..<6, id: \.self) { _ in
          SkeletonCardView(cardSize: size)
        }
      } else {
        ForEach(videos, id: \.videoId) { video in
          if let track = track.first(where: { $0.videoId == video.videoId.uuidString }) {
            GridCell(
              size: size,
              videoId: video.videoId.uuidString,
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
              showEditSheet: { self.showEditVideoTitle = video },
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
              },
              sectionCount: section.count
            )
          }
        }
      }
    }
    // MARK: 비디오 이름 수정 뷰
    .sheet(item: $showEditVideoTitle) { video in
        NavigationStack {
          VideoTitleEditView(
            video: video,
            tracksId: tracksId,
            vm: $vm,
            videoTitle: video.videoTitle
          )
      }
    }
    // MARK: 삭제 알랏
    .alert(
      "\(selectedVideo?.videoTitle ?? "영상")을/를 삭제하시겠어요?",
      isPresented: $showDeleteAlert) {
        Button("취소", role: .cancel) { }
        Button("삭제", role: .destructive) {
          if let video = selectedVideo {
            Task {
              await vm.deleteVideo(
                video: video,
                tracksId: tracksId
              )
            }
          }
        }
      } message: {
        Text("삭제하면 복구할 수 없습니다.")
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
