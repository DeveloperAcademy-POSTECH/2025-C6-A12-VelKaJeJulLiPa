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
          .font(.system(size: 14))
          .foregroundStyle(.purple)
        Text(text)
          .font(.system(size: 14))
          .foregroundStyle(.purple)
      }
      .padding(.horizontal, 6)
      .padding(.vertical, 4)
      .background {
        RoundedRectangle(cornerRadius: 1000)
          .fill(Color.gray.opacity(0.6))
          .stroke(Color.purple)
      }
    }
  }
}

#Preview {
  TimestampButton(text: "00:05", timeSeek: {})
}
