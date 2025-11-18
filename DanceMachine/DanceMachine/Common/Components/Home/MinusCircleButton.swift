//
//  MinusCircleButton.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/16/25.
//

import SwiftUI

struct CheckCircleButton: View {
  
  let isSelected: Bool
  let action: () -> Void
  
  var body: some View {
    Button {
      action()
    } label: {
      Image(systemName: "checkmark.circle.fill")
        .resizable()
        .scaledToFit()
        .frame(width: 23, height: 23)
        .foregroundStyle(
          isSelected ? Color.secondaryStrong : Color.fillAssitive 
        )
    }
    .buttonStyle(.plain)
    .contentShape(Rectangle())
  }
}

#Preview {
  ZStack {
    Color.backgroundNormal.ignoresSafeArea()
    CheckCircleButton(isSelected: true) {}
  }
}
