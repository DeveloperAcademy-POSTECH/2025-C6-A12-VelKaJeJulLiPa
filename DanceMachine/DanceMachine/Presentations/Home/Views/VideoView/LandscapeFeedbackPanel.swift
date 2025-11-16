//
//  LandscapeFeedbackPanel.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/16/25.
//

import SwiftUI

struct LandscapeFeedbackPanel: View {
  @Bindable var vm: VideoDetailViewModel

  @Binding var feedbackFilter: FeedbackFilter
  @Binding var pointTime: Double
  @Binding var intervalTime: Double
  @Binding var showFeedbackInput: Bool
  @Binding var scrollProxy: ScrollViewProxy?

  let filteredFeedback: [Feedback]
  let userId: String
  let videoId: String
  let imageNamespace: Namespace.ID

  @Binding var selectedFeedbackImageURL: String?
  @Binding var showFeedbackImageFull: Bool

  let onFeedbackSelect: (Feedback) -> Void
  let onClose: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      // MARK: 헤더
      HStack(spacing: 0) {
        FeedbackSection(feedbackFilter: $feedbackFilter)
          .padding(.vertical, 10)
        Spacer()
        Button {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            onClose()
          }
        } label: {
          Image(systemName: "xmark.circle")
            .font(.system(size: 20))
            .foregroundStyle(.labelStrong)
        }
        .frame(width: 33, height: 33)
        .contentShape(Rectangle())
      }
      .padding(.horizontal, 12)

      Divider().foregroundStyle(.strokeNormal)

      // MARK: 피드백 리스트
      FeedbackListView(
        vm: vm,
        pointTime: $pointTime,
        intervalTime: $intervalTime,
        scrollProxy: $scrollProxy,
        filteredFeedbacks: filteredFeedback,
        userId: userId,
        onFeedbackNavigate: { feedback in
          onFeedbackSelect(feedback)
        },
        imageNamespace: imageNamespace,
        selectedFeedbackImageURL: $selectedFeedbackImageURL,
        showFeedbackImageFull: $showFeedbackImageFull
      )
      .scrollIndicators(.hidden)
      
      Button {
        self.showFeedbackInput = true
      } label: {
        Text("dd")
      }
      .frame(maxWidth: .infinity)
      .frame(height: 49)
    }
    .background(Color.backgroundNormal)
  }
}
