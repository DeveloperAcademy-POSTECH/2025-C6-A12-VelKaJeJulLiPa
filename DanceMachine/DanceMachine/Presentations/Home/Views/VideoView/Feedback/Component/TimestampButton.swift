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

#Preview {
  TimestampButton(text: "00:05", timeSeek: {})
}
