//
//  VideoController.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/3/25.
//

import SwiftUI
import AVKit

struct VideoController: UIViewControllerRepresentable {
  let player: AVPlayer
  
  func makeUIViewController(context: Context) -> AVPlayerViewController {
    let controller = AVPlayerViewController()
    controller.player = player
    controller.showsPlaybackControls = false
    controller.videoGravity = .resizeAspect
    
    return controller
  }
  
  func updateUIViewController(
    _ uiViewController: AVPlayerViewController,
    context: Context
  ) {
    uiViewController.player = player
  }
}

#Preview {
  VideoController(player: AVPlayer())
}
