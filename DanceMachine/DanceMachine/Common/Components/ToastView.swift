//
//  ToastView.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/5/25.
//

import SwiftUI


struct ToastView: View {
  var text: String
  var icon: ToastIcon
  
  var body: some View {
    HStack(spacing: 8) {

      Group {
        if icon == .warning {
          Image(systemName: icon.icon)
            .font(.system(size: 19))
            .foregroundStyle(icon.iconColor)
            .symbolEffect(.wiggle, options: .repeating)
        } else {
            Image(systemName: icon.icon)
              .font(.system(size: 19))
              .foregroundStyle(icon.iconColor)
              .symbolEffect(.bounce.up.byLayer, options: .repeat(2))
        }
      }

      Text(text)
        .font(.headline2Medium)
        .foregroundStyle(.labelStrong)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 43, alignment: .leading)

    }
    .padding(.leading, 16)
    .background(
      RoundedRectangle(cornerRadius: 10)
        .fill(Color.fillAssitive)
    )
    .onAppear {
      // 햅틱 피드백
      let generator = UINotificationFeedbackGenerator()
      generator.notificationOccurred(icon == .warning ? .warning : .success)
    }
  }
}

#Preview {
  ToastView(text: "배고프다", icon: .check)
}
