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
  var initialMarkupData: Data? // 편집 모드일 때 기존 마크업 데이터

  init(
    size: CGSize,
    image: UIImage?,
    feedbackPaperDrawingData: FeedbackPaperDrawingData,
    initialMarkupData: Data? = nil
  ) {
    self.size = size
    self.image = image
    self._feedbackPaperDrawingData = .init(initialValue: feedbackPaperDrawingData)
    self.initialMarkupData = initialMarkupData
  }

  var body: some View {
    if let controller = feedbackPaperDrawingData.controller {
      // 컨트롤러가 준비되면 PaperKit 뷰 표시
      PaperControllerView(controller: controller) {
        // 컨트롤러가 화면에 표시된 후 툴피커 자동 표시
        feedbackPaperDrawingData.showPencilKitTools(true)
      }
    } else {
      // 컨트롤러 준비 중 로딩 표시
      ProgressView()
        .onAppear {
          // 분기 처리: 편집 모드 vs 새 드로잉
          if let data = initialMarkupData,
             let imageSize = image?.size {
            // 편집 모드: 저장된 마크업 데이터 로드
            try? feedbackPaperDrawingData.loadMarkupData(data, size: imageSize)
          } else {
            // 새 드로잉: 빈 캔버스 초기화
            feedbackPaperDrawingData.initiakizeController(size, image: image)
          }
        }
    }
  }
}


/// Paper Controller View
@available(iOS 26.0, *)
fileprivate struct PaperControllerView: UIViewControllerRepresentable {
  var controller: PaperMarkupViewController
  var onControllerReady: (() -> Void)? = nil

  func makeUIViewController(context: Context) -> some PaperMarkupViewController {
    let bgView = UIView()
    bgView.backgroundColor = UIColor(Color.black)
    controller.contentView = bgView

    // 컨트롤러가 준비되면 콜백 호출
    DispatchQueue.main.async {
      onControllerReady?()
    }

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
