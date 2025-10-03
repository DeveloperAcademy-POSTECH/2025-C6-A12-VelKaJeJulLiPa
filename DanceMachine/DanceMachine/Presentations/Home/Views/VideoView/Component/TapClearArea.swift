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
          showControls.toggle()
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
    showControls: .constant(true))
}
