//
//  TimestampButton.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/26/25.
//

import SwiftUI

struct TimestampButton: View {
  let text: String
  let timeSeek: () -> Void
  
  var body: some View {
    Button {
      timeSeek()
    } label: {
      HStack(spacing: 4) {
        Image(systemName: "clock")
          .font(.system(size: 18))
          .foregroundStyle(.secondaryNormal)
        Text(text)
          .font(.headline2Medium)
          .foregroundStyle(.secondaryNormal)
      }
    }
  }
}

struct TimestampInput: View {
  let text: String
  let timeSeek: () -> Void
  
  var body: some View {
    Button {
      timeSeek()
    } label: {
      HStack(spacing: 4) {
        Image(systemName: "clock")
          .font(.footnoteMedium)
          .foregroundStyle(.labelStrong)
        Text(text)
          .font(.footnoteMedium)
          .foregroundStyle(.labelStrong)
      }
      .padding(.vertical, 6)
      .padding(.horizontal, 8)
    }
    .background {
      RoundedRectangle(cornerRadius: 1000)
        .fill(Color.secondaryStrong)
        .stroke(Color.labelStrong, lineWidth: 1)
    }
  }
}

#Preview("피드백, 댓글 창") {
  TimestampButton(text: "00:05", timeSeek: {})
}

#Preview("피드백 입력 키보드 오버레이") {
  TimestampInput(text: "00:05", timeSeek: {})
}
