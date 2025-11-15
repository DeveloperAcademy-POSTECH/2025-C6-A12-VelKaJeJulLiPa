//
//  FeedbackSection.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/16/25.
//

import SwiftUI

struct FeedbackSection: View {
  @Binding var feedbackFilter: FeedbackFilter
  
  var body: some View {
    HStack {
      Text(feedbackFilter == .all ? "전체 피드백" : "마이 피드백")
        .font(.heading1SemiBold)
        .foregroundStyle(.labelStrong)
      Spacer()
      Button {
        switch feedbackFilter {
        case .all:
          self.feedbackFilter = .mine
        case .mine:
          self.feedbackFilter = .all
        }
      } label: {
        Text("마이피드백")
          .foregroundStyle(feedbackFilter == .all ? .secondaryAssitive : .labelStrong)
          .padding(.horizontal, 11)
          .padding(.vertical, 7)
          .background(
            RoundedRectangle(cornerRadius: 10)
              .fill(feedbackFilter == .all ? .backgroundElevated : .secondaryStrong)
              .stroke(feedbackFilter == .all ? .secondaryAssitive : .secondaryNormal)
          )
      }
    }
  }
}

//#Preview {
//  FeedbackSection()
//}
