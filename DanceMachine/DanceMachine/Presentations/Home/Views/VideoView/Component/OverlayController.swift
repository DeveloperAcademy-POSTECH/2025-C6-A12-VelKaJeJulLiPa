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
      HStack(spacing: 30) {
        leftButton
        centerButton
        rightButton
      }
    }
    .ignoresSafeArea()
  }
  
  private var leftButton: some View {
    Button {
      leftAction()
    } label: {
      Image(systemName: "gobackward.5")
        .font(.system(size: 30))
        .foregroundStyle(.labelStrong)
    }
    .frame(width: 55, height: 55)
    .overlayController()
  }
  
  private var centerButton: some View {
    Button {
      centerAction()
    } label: {
      Image(
        systemName: isPlaying ? "pause.fill" : "play.fill"
      )
      .font(.system(size: 44))
      .foregroundStyle(.labelStrong)
    }
    .frame(width: 70, height: 70)
    .overlayController()
  }
  
  private var rightButton: some View {
    Button {
      rightAction()
    } label: {
      Image(systemName: "goforward.5")
        .font(.system(size: 30))
        .foregroundStyle(.labelStrong)
    }
    .frame(width: 55, height: 55)
    .overlayController()
  }
}

#Preview {
  OverlayController(
    leftAction: {},
    rightAction: {},
    centerAction: {},
    isPlaying: .constant(true)
  )
//  .preferredColorScheme(.dark)
}
