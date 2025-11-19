//
//  VideoTitleEditView.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/6/25.
//

import SwiftUI

struct VideoTitleEditView: View {
  @Environment(\.dismiss) private var dismiss
  let video: Video
  let tracksId: String
  @Binding var vm: VideoListViewModel
  
  @State var videoTitle: String
  @State private var showExitAlert: Bool = false
  
  // 변경사항 여부 체크
  var hasChanges: Bool {
    self.videoTitle != video.videoTitle
  }
  
  var body: some View {
    VStack {
      inputVideoTitleView
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity, alignment: .center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.backgroundElevated)
    .dismissKeyboardOnTap()
    .safeAreaInset(edge: .bottom) {
      bottomButtonView
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    .toolbar {
      ToolbarLeadingBackButton(icon: .xmark) {
        if hasChanges {
          self.showExitAlert = true
        } else {
          dismiss()
        }
      }
      ToolbarCenterTitle(text: "비디오 이름 수정")
    }
    .unsavedChangesAlert(
      isPresented: $showExitAlert,
      onConfirm: { dismiss() }
    )
  }
  
  private var inputVideoTitleView: some View {
    VStack {
      RoundedRectangle(cornerRadius: 10)
        .fill(Color.fillStrong)
        .frame(maxWidth: .infinity)
        .frame(height: 47)
        .overlay {
          TextField("비디오 제목", text: $videoTitle)
            .padding([.leading, .vertical], 16)
            .padding(.trailing, videoTitle.count >= 21 ? 20 : 16) // X버튼(44pt) 공간 확보
            .font(.headline2Medium)
            .foregroundStyle(.labelStrong)
            .multilineTextAlignment(.center)
            .onChange(of: videoTitle) { oldValue, newValue in
              let updated = newValue.sanitized(limit: 21)
              if updated != videoTitle {
                videoTitle = updated
              }
            }
        }
        .overlay(
          RoundedRectangle(cornerRadius: 10)
            .stroke(videoTitle.count > 20 ? Color.accentRedNormal : Color.clear, lineWidth: 2)
        )
        .overlay(alignment: .trailing) {
          if videoTitle.count >= 21 {
            Button {
              videoTitle = ""
            } label: {
              Image(systemName: "xmark.circle.fill")
                .frame(width: 44, height: 44)
                .foregroundStyle(.labelNormal)
            }
          }
        }
      
      Spacer().frame(height: 16)
      
      Text("20자 이하로 입력해주세요.")
        .font(.footnoteMedium)
        .foregroundStyle(.accentRedNormal)
        .opacity(videoTitle.count < 21 ? 0 : 1)
    }
  }
  
  private var bottomButtonView: some View {
    ActionButton(
      title: "확인",
      color: self.videoTitle.isEmpty ? Color.fillAssitive : Color.secondaryStrong,
      height: 47,
      isEnabled: self.videoTitle.isEmpty ? false : true
    ) {
      Task {
        await vm.updateVideoTitle(
          video: video,
          newTitle: videoTitle,
          tracksId: tracksId
        )
        await MainActor.run { dismiss() }
      }
    }
  }
}

#Preview {
  @Previewable @State var vm: VideoListViewModel = .preview
  NavigationStack {
    VideoTitleEditView(video: vm.videos[0], tracksId: "", vm: $vm, videoTitle: vm.videos[0].videoTitle)
  }
}
