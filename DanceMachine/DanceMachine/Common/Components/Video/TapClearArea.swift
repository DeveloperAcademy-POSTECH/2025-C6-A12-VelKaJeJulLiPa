//
//  TapArea.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/3/25.
//

import SwiftUI

struct TapClearArea: View {
  let leftTap: () -> Void
  let rightTap: () -> Void
  let centerTap: () -> Void

  @Binding var showControls: Bool

  var body: some View {
    HStack {
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture {
          leftTap()
        }
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture {
          centerTap()
        }
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture {
          rightTap()
        }
    }
  }
}

#Preview {
  TapClearArea(
    leftTap: {},
    rightTap: {},
    centerTap: {},
    showControls: .constant(true))
}
