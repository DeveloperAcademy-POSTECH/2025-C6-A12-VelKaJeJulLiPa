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
  
  // 확대 배율 범위
  var minZoom: CGFloat = 1
  var maxZoom: CGFloat = 8
  
  // 컨텐츠 컨테이너 식별용 태그
  private let contentTag = 9999
  
  func makeCoordinator() -> Coordinator { Coordinator(self) }
  
  final class Coordinator: NSObject, UIScrollViewDelegate {
    let parent: PencilCanvasView
    init(_ parent: PencilCanvasView) { self.parent = parent }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
      scrollView.subviews.first(where: { $0.tag == parent.contentTag })
    }
    
    // 컨텐츠가 화면보다 작아질 때 중앙 정렬 유지
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
      guard let content = viewForZooming(in: scrollView) else { return }
      let sv = scrollView.bounds.size
      let cs = content.frame.size
      let h = max(0, (sv.width  - cs.width)  / 2)
      let v = max(0, (sv.height - cs.height) / 2)
      scrollView.contentInset = UIEdgeInsets(top: v, left: h, bottom: v, right: h)
    }
  }
  
  func makeUIView(context: Context) -> UIScrollView {
    // 1) 스크롤뷰 (줌 담당)
    let scroll = UIScrollView()
    scroll.backgroundColor = .clear
    scroll.delegate = context.coordinator
    scroll.minimumZoomScale = minZoom
    scroll.maximumZoomScale = maxZoom
    scroll.bouncesZoom = true
    scroll.alwaysBounceVertical = true
    scroll.alwaysBounceHorizontal = true
    scroll.showsVerticalScrollIndicator = false
    scroll.showsHorizontalScrollIndicator = false
    scroll.contentInsetAdjustmentBehavior = .never
    
    // 2) 컨텐츠 컨테이너(여기에 이미지+캔버스 겹침)
    let content = UIView()
    content.translatesAutoresizingMaskIntoConstraints = false
    content.backgroundColor = .clear
    content.tag = contentTag
    
    // 3) 배경 이미지
    let bg = UIImageView()
    bg.translatesAutoresizingMaskIntoConstraints = false
    bg.backgroundColor = UIColor(Color.materialDimmer)
    bg.contentMode = .scaleAspectFit
    bg.clipsToBounds = true
    bg.image = image
    
    // 4) PKCanvasView 설정 (스크롤/줌은 외부 스크롤뷰가 담당)
    canvasView.translatesAutoresizingMaskIntoConstraints = false
    canvasView.backgroundColor = .clear
    canvasView.drawingPolicy = .anyInput
    canvasView.tool = tool
    canvasView.isScrollEnabled = false
    canvasView.alwaysBounceVertical = false
    canvasView.alwaysBounceHorizontal = false
    canvasView.minimumZoomScale = 1
    canvasView.maximumZoomScale = 1
    canvasView.isMultipleTouchEnabled = true
    
    // 5) 계층/제약
    scroll.addSubview(content)
    content.addSubview(bg)
    content.addSubview(canvasView)
    
    NSLayoutConstraint.activate([
      // 컨텐츠는 스크롤뷰 콘텐츠 레이아웃에 붙이고, 기본 크기는 프레임과 동일
      content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
      content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
      content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
      content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
      content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
      content.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor),
      
      // 배경/캔버스는 컨텐츠에 꽉 차게
      bg.leadingAnchor.constraint(equalTo: content.leadingAnchor),
      bg.trailingAnchor.constraint(equalTo: content.trailingAnchor),
      bg.topAnchor.constraint(equalTo: content.topAnchor),
      bg.bottomAnchor.constraint(equalTo: content.bottomAnchor),
      
      canvasView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
      canvasView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
      canvasView.topAnchor.constraint(equalTo: content.topAnchor),
      canvasView.bottomAnchor.constraint(equalTo: content.bottomAnchor),
    ])
    
    return scroll
  }
  
  func updateUIView(_ scroll: UIScrollView, context: Context) {
    // 이미지/툴 갱신
    if let content = scroll.subviews.first(where: { $0.tag == contentTag }),
       let bg = content.subviews.first(where: { $0 is UIImageView }) as? UIImageView {
      bg.image = image
      bg.contentMode = .scaleAspectFit
    }
    canvasView.tool = tool
  }
}

//#Preview {
//  FeedbackPencilDrawingView(
//    image: <#T##Binding<UIImage?>#>,
//  )
//}
