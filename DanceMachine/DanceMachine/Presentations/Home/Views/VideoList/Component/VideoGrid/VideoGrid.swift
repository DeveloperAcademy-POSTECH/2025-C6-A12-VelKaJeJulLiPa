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
  let pickerViewModel: VideoPickerViewModel

  @State private var selectedVideo: Video?
  @State private var selectedTrack: Track?
  @State private var showDeleteAlert: Bool = false
  @State private var showEditVideoTitle: Video?
  @State private var reportTargetVideo: Video?
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
      switch progressManager.uploadState {
      case .compressing, .uploading, .failed, .fileToLarge:
        UploadProgressCard(
          cardSize: size,
          progressManager: progressManager,
          onRetry: { await pickerViewModel.retryUpload() },
          onCancel: { await pickerViewModel.cancelUpload() }
        )
      case .idle:
        EmptyView()
      }
      if vm.isLoading {
        ForEach(0..<8, id: \.self) { _ in
          SkeletonCardView(cardSize: size)
        }
      } else {
        ForEach(videos, id: \.videoId) { video in
          if let track = track.first(where: { $0.videoId == video.videoId.uuidString }) {
            let currentUserId = FirebaseAuthManager.shared.userInfo?.userId ?? ""
            let currentTeamspaceId: String = FirebaseAuthManager.shared.currentTeamspace?.teamspaceId.uuidString ?? ""
            
            GridCell(
              size: size,
              videoId: video.videoId.uuidString,
              thumbnailURL: video.thumbnailURL,
              title: video.videoTitle,
              duration: video.videoDuration,
              uploadDate: video.createdAt ?? Date(),
              currentUserId: currentUserId,
              videoUploaderId: video.uploaderId,
              editAction: {
                self.selectedTrack = track
              },
              deleteAction: {
                self.selectedVideo = video
                self.showDeleteAlert = true
                print("\(video.videoId)모달 선택")
              },
              showEditSheet: { self.showEditVideoTitle = video },
              showCreateReportSheet: { self.reportTargetVideo = video },
              videoAction: {
                router.push(
                  to: .video(
                    .play(
                      videoId: video.videoId.uuidString,
                      videoTitle: video.videoTitle,
                      videoURL: video.videoURL,
                      teamspaceId: currentTeamspaceId
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
    .fullScreenCover(item: $selectedTrack, onDismiss: {
      // 영상 이동 후 캐시에서 최신 데이터 로드
      Task {
        await vm.loadFromServer(tracksId: tracksId)
      }
    }) { track in
      NavigationStack {
        SectionSelectView(
          section: section,
          sectionId: track.sectionId,
          track: track,
          tracksId: tracksId
        )
      }
    }
    
    // MARK: 신고하기 뷰
    .sheet(item: $reportTargetVideo) { video in
      NavigationStack {
        CreateReportView(
          reportedId: video.uploaderId,
          reportContentType: .video,
          video: video,
          toastReceiveView: ReportToastReceiveViewType.videoListView
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
      thumbnailURL: "",
      uploaderId: ""
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
    pickerViewModel: VideoPickerViewModel(),
    vm: .constant(VideoListViewModel())
  )
}
