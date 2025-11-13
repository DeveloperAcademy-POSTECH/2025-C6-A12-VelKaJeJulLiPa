//
//  PencilCanvasView.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/13/25.
//

import SwiftUI
import PencilKit

struct PencilCanvasView: UIViewRepresentable {
  @Binding var canvasView: PKCanvasView
  var tool: PKTool
  var allowsFingerDrawing: Bool = true
  var image: UIImage?
  
  func makeUIView(context: Context) -> UIView {
    let container = UIView()
    container.backgroundColor = .clear
    
    // 1) 배경 이미지 (AspectFit)
    let bg = UIImageView()
    bg.translatesAutoresizingMaskIntoConstraints = false
    bg.backgroundColor = UIColor(Color.materialDimmer)
    bg.contentMode = .scaleAspectFit
    bg.clipsToBounds = true
    bg.image = image
    
    // 2) 드로잉 캔버스 (투명, 스크롤/줌 비활성)
    canvasView.translatesAutoresizingMaskIntoConstraints = false
    canvasView.backgroundColor = .clear
    canvasView.drawingPolicy = .anyInput
    canvasView.tool = tool
    canvasView.isScrollEnabled = false
    canvasView.alwaysBounceVertical = false
    canvasView.alwaysBounceHorizontal = false
    canvasView.minimumZoomScale = 1.0
    canvasView.maximumZoomScale = 1.0
    
    // 3) 레이어링: 이미지 아래, 캔버스 위
    container.addSubview(bg)
    container.addSubview(canvasView)
    
    NSLayoutConstraint.activate([
      bg.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      bg.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      bg.topAnchor.constraint(equalTo: container.topAnchor),
      bg.bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor),
      
      canvasView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      canvasView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      canvasView.topAnchor.constraint(equalTo: container.topAnchor),
      canvasView.bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor)
    ])
    
    return container
  }
  
  func updateUIView(_ view: UIView, context: Context) {
    // 이미지 업데이트
    if let bg = view.subviews.first(where: { $0 is UIImageView }) as? UIImageView {
      bg.image = image
      bg.contentMode = .scaleAspectFit
    }
    // 툴/옵션 업데이트
    canvasView.tool = tool
  }
}

//#Preview {
//  FeedbackPencilDrawingView(
//    image: <#T##Binding<UIImage?>#>,
//  )
//}
