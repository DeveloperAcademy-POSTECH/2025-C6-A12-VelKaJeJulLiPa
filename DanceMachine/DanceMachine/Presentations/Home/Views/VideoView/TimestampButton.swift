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
      HStack {
        Image(systemName: "clock")
          .foregroundStyle(.purple)
        Text(text)
          .foregroundStyle(.purple)
      }
      .padding(.horizontal, 6)
      .padding(.vertical, 4)
      .background(Color.gray.opacity(0.5))
      .clipShape(RoundedRectangle(cornerRadius: 1000))
    }
  }
}

#Preview {
  TimestampButton(text: "00:05", timeSeek: {})
}
