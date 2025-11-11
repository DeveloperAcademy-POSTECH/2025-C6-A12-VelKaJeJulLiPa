//
//  FeedbackDrawingView.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/6/25.
//

import SwiftUI
import PaperKit
import PencilKit

@available(iOS 26.0, *)
struct FeedbackPaperDrawingEditView: View {
  var size: CGSize
  var image: UIImage?
  @State var feedbackPaperDrawingData: FeedbackPaperDrawingData
  
  init(
    size: CGSize,
    image: UIImage?,
    feedbackPaperDrawingData: FeedbackPaperDrawingData
  ) {
    self.size = size
    self.image = image
    self._feedbackPaperDrawingData = .init(initialValue: feedbackPaperDrawingData)
  }
  
  var body: some View {
    if let controller = feedbackPaperDrawingData.controller {
      PaperControllerView(controller: controller)
    } else {
      ProgressView()
        .onAppear {
          feedbackPaperDrawingData.initiakizeController(size, image: image)
        }
    }
  }
}


/// Paper Controller View
@available(iOS 26.0, *)
fileprivate struct PaperControllerView: UIViewControllerRepresentable {
  var controller: PaperMarkupViewController
  
  func makeUIViewController(context: Context) -> some PaperMarkupViewController {
    return controller
  }
  
  func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    
  }
}


#Preview {
  if #available(iOS 26.0, *) {
    FeedbackPaperDrawingView(image: .constant(nil))
  } else {
    // Fallback on earlier versions
  }
}
