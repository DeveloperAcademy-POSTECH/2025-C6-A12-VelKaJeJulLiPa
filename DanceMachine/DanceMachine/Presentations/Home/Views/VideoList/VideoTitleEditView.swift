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
            .font(.headline2Medium)
            .foregroundStyle(.labelStrong)
            .multilineTextAlignment(.center)
            .onChange(of: videoTitle) { oldValue, newValue in
              var updated = newValue
              
              // Prevent leading space as the first character
              if updated.first == " " {
                updated = String(updated.drop(while: { $0 == " " })) // ❗️공백 금지
              }
              
              // Enforce 20-character limit
              if updated.count > 20 {
                updated = String(updated.prefix(20)) // ❗️20글자 초과 금지
              }
              
              if updated != videoTitle {
                videoTitle = updated
              }
            }
        }
        .overlay(
          RoundedRectangle(cornerRadius: 10)
            .stroke(videoTitle.count > 19 ? Color.red : Color.clear, lineWidth: 2)
        )
        .overlay(alignment: .trailing) {
          if videoTitle.count >= 20 {
            Image(systemName: "xmark.circle.fill")
              .frame(width: 44, height: 44)
              .foregroundStyle(.labelNormal)
          }
        }
      
      Spacer().frame(height: 16)
      
      Text("20자 이내로 입력해주세요.")
        .font(.footnoteMedium)
        .foregroundStyle(.accentRedNormal)
        .opacity(videoTitle.count < 20 ? 0 : 1)
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
        NotificationCenter.post(.showEditVideoTitleToast, object: nil)
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
