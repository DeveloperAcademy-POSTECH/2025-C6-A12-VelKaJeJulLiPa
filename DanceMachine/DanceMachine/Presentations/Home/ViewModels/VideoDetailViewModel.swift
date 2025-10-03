//
//  VideoDetailViewModel.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/4/25.
//

import Foundation

@Observable
final class VideoDetailViewModel {
  var videoVM: VideoViewModel
  var feedbackVM: FeedbackViewModel
  
  init(videoURL: String) {
    self.videoVM = VideoViewModel()
    self.feedbackVM = FeedbackViewModel()
    
    videoVM.setupPlayer(from: videoURL)
  }
}
