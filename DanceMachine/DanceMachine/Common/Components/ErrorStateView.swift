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
  let action: () -> Void
  
  @State private var isRotating: Bool = false
  
  init(
     mainSymbol: String? = nil,
     message: String,
     action: @escaping () -> Void
   ) {
     self.mainSymbol = mainSymbol
     self.message = message
     self.action = action
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
          .symbolEffect(
            .rotate.wholeSymbol,
            options: .repeat(1).speed(1.5),
            isActive: isRotating
          )
          .onTapGesture {
             isRotating.toggle()
             DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
               action()
             }
           }      }
    }
  }
}

#Preview {
  ErrorStateView(
    mainSymbol: "exclamationmark.triangle.fill",
    message: "메시지를 입력해주세요.",
    action: { print("action") }
  )
}

#Preview {
  ErrorStateView(
    message: "메시지를 입력해주세요.",
    action: { print("action") }
  )
}

