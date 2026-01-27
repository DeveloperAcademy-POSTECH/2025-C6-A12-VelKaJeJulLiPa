//
//  FeedbackSection.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/16/25.
//

import SwiftUI

struct FeedbackSection: View {
  @Binding var feedbackFilter: FeedbackFilter
  
  private var filterTitle: String {
    switch feedbackFilter {
    case .all: return "전체 피드백"
    case .mine: return "마이 피드백"
    case .ai: return "AI 분석"
    }
  }
  
  var body: some View {
    HStack {
      //      Text(feedbackFilter == .all ? "전체 피드백" : "마이 피드백")
      //        .font(.heading1SemiBold)
      //        .foregroundStyle(.labelStrong)
      feedbackToggle
      Spacer()
      aiToggle
    }
  }
  
  private var feedbackToggle: some View {
    Button {
      //        switch feedbackFilter {
      //        case .all:
      //          self.feedbackFilter = .mine
      //        case .mine:
      //          self.feedbackFilter = .all
      //        }
    } label: {
      Text(filterTitle)
        .foregroundStyle(feedbackFilter == .all ? .secondaryAssitive : .labelStrong)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(
          RoundedRectangle(cornerRadius: 10)
            .fill(feedbackFilter == .all ? .backgroundElevated : .secondaryStrong)
            .stroke(feedbackFilter == .all ? .secondaryAssitive : .secondaryNormal)
        )
        .disabled(feedbackFilter == .ai)
        .simultaneousGesture(
          TapGesture()
            .onEnded {
              if feedbackFilter != .ai {
                switch feedbackFilter {
                case .all:
                  self.feedbackFilter = .mine
                case .mine:
                  self.feedbackFilter = .all
                case .ai:
                  break
                }
              }
            }
        )
    }
  }
  
  private var aiToggle: some View {
    HStack(spacing: 2) {
      Image(systemName: "sparkles")
      Text("AI")
    }
    .foregroundStyle(feedbackFilter == .ai ? .white : .secondaryStrong)
    .padding(.horizontal, 11)
    .padding(.vertical, 7)
    .background {
      RoundedRectangle(cornerRadius: 10)
        .fill(feedbackFilter == .ai ? .accentRedStrong : .backgroundElevated)
        .stroke(feedbackFilter == .ai ? .accentRedStrong : .secondaryAssitive)
    }
    .simultaneousGesture(
      TapGesture()
        .onEnded {
          if feedbackFilter == .ai {
            self.feedbackFilter = .all
          } else {
            self.feedbackFilter = .ai
          }
        }
    )
  }
}

#Preview {
  FeedbackSection(feedbackFilter: .constant(FeedbackFilter.all))
}
