//
//  CheckmarkButton.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/10/25.
//

import SwiftUI

struct CheckmarkButton: View {
  
  let disable: Bool
  let action: () -> Void
  
  var body: some View {
    Button {
      action()
    } label: {
      Circle()
        .fill(disable ? .clear : Color.accentBlueStrong)
        .frame(width: 44, height: 44)
    }
    .overlay {
      Image(systemName: "checkmark")
        .resizable()
        .scaledToFit()
        .frame(width: 24, height: 24)
        .foregroundStyle(disable ? Color.labelAssitive : Color.labelStrong)
    }
    .background(
      Circle()
        .clearGlassButtonIfAvailable()
    )
  }
}

#Preview {
  CheckmarkButton(disable: true) {}
}
