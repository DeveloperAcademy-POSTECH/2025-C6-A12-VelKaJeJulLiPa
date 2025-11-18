//
//  ErrorStateView.swift
//  DanceMachine
//
//  Created by Paidion on 11/18/25.
//

import SwiftUI

struct ErrorStateView: View {
  let mainSymbol: String?
  let message: String
  let isAnimating: Bool
  let onRetry: () -> Void
  
  init(
     mainSymbol: String? = nil,
     message: String,
     isAnimating: Bool,
     onRetry: @escaping () -> Void
   ) {
     self.mainSymbol = mainSymbol
     self.message = message
     self.isAnimating = isAnimating
     self.onRetry = onRetry
   }
  
  var body: some View {
    VStack(spacing: 16) {
      
      if let mainSymbol {
        Image(systemName: mainSymbol)
          .font(.system(size: 75))
          .foregroundStyle(Color.labelAssitive)
      }
      
      VStack(spacing: 8) {
        Text(message)
          .multilineTextAlignment(.center)
          .foregroundStyle(Color.labelStrong)
        
        Image(systemName: "arrow.trianglehead.clockwise")
          .foregroundStyle(Color.labelStrong)
          .symbolEffect(.rotate.wholeSymbol, options: .nonRepeating, value: isAnimating)
          .onTapGesture { onRetry() }
      }
    }
  }
}

#Preview {
  ErrorStateView(
    mainSymbol: "exclamationmark.triangle.fill",
    message: "메시지가 이렇게 보입니다.",
    isAnimating: true,
    onRetry: { print("onRetry") }
  )
}

#Preview {
  ErrorStateView(
    message: "메시지가 이렇게 보입니다.",
    isAnimating: false,
    onRetry: { print("onRetry") }
  )
}

