//
//  OverlayController.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/3/25.
//

import SwiftUI

struct OverlayController: View {
  let leftAction: () -> Void
  let rightAction: () -> Void
  let centerAction: () -> Void
  
  @Binding var isPlaying: Bool
  
  var body: some View {
    VStack {
      Spacer()
      overlayController
      Spacer()
    }
  }
  
  private var overlayController: some View {
    HStack(spacing: 60) {
      leftButton
      centerButton
      rightButton
    }
  }
  
  private var leftButton: some View {
    Button {
      leftAction()
    } label: {
      Image(systemName: "gobackward.5")
        .resizable()
        .frame(width: 40, height: 40)
    }
  }
  
  private var centerButton: some View {
    Button {
      centerAction()
    } label: {
      Image(
        systemName: isPlaying ? "pause.fill" : "play.fill"
      )
      .resizable()
      .frame(width: 40, height: 40)
    }
  }
  
  private var rightButton: some View {
    Button {
      rightAction()
    } label: {
      Image(systemName: "goforward.5")
        .resizable()
        .frame(width: 40, height: 40)
    }
  }
}

#Preview {
  OverlayController(
    leftAction: {},
    rightAction: {},
    centerAction: {}, isPlaying: .constant(true)
  )
}
