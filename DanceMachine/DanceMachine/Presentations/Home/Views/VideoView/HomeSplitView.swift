//
//  HomeSplitView.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/22/25.
//

import SwiftUI

/// iPad 전용  SplitView 입니다
/// (프로젝트/트랙 목록  |  비디오 목록 )
struct HomeSplitView: View {
  @State private var vm: HomeViewModel = .init()
  @State private var selectedTrack: SelectedTrackInfo?
  @State private var columnVisibility: NavigationSplitViewVisibility = .all

  @State private var sectionId: String = ""

  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      HomeView(onTrackSelect: { track in
        Task {
          do {
            let section = try await vm.fetchSection(tracks: track)
            guard let first = section.first else {
              print("section 없음")
              return
            }
            self.sectionId = first.sectionId

            await MainActor.run {
              selectedTrack = SelectedTrackInfo(
                tracksId: track.tracksId.uuidString,
                sectionId: first.sectionId,
                trackName: track.trackName
              )
              print("섹션 있음")
            }
          } catch {
            print("Failed to fetch section: \(error)")
          }
        }
      })
      .navigationSplitViewColumnWidth(min: 350, ideal: 350, max: 400)
    } detail: {
      if let track = selectedTrack {
        VideoListView(
          tracksId: track.tracksId,
          sectionId: sectionId,
          trackName: track.trackName,
          onBackButtonTap: {
            selectedTrack = nil
          }
        )
        .id(track.tracksId) // tracksId가 바뀔 때마다 뷰 재생성
        .transition(.opacity)
      } else {
        emptyTrackDetailView
          .transition(.opacity)
      }
    }
    .ignoresSafeArea()
    .navigationSplitViewStyle(.balanced)
  }

  private var emptyTrackDetailView: some View {
    ZStack {
      Color.backgroundNormal
        .ignoresSafeArea()

      VStack(spacing: 16) {
        Image(systemName: "music.note.list")
          .font(.system(size: 60))
          .foregroundStyle(.labelAssitive)
        Text("곡을 선택해주세요")
          .font(.body)
          .foregroundStyle(.labelNormal)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct SelectedTrackInfo: Equatable {
  let tracksId: String
  let sectionId: String
  let trackName: String
}

#Preview {
  HomeSplitView()
    .environmentObject(MainRouter())
    .preferredColorScheme(.dark)
}
