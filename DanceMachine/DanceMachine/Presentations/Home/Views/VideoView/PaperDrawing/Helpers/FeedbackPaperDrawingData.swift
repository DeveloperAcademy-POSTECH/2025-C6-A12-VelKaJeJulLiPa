//
//  FeedbackDrawingViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/6/25.
//

import SwiftUI
import PencilKit
import PaperKit

@available(iOS 26.0, *)
@Observable
final class FeedbackPaperDrawingData {
  var controller: PaperMarkupViewController?
  var toolPicker = PKToolPicker()
  var featureSet: FeatureSet = {
    var featureSet = FeatureSet.latest
    featureSet.colorMaximumLinearExposure = 4 // HDR 범위
    return featureSet
  }()
  
  var canvasBackgroundColor: UIColor = .white
  
  // MARK: - 초기화
  
  /// PaperKit 컨트롤러 + 캔버스 초기화
  /// - Parameters:
  ///   - size: SwiftUI에서 넘어온 뷰 사이즈
  ///   - image: 처음 캔버스에 올릴 기본 이미지 (없으면 nil)
  func initiakizeController(
    _ size: CGSize,
    image: UIImage?
  ) {
    let rect = CGRect(origin: .zero, size: size) // 기기 사이즈
    
    // markup과 controller를 함께 초기화
    let markup = PaperMarkup(bounds: rect)
    let controller = PaperMarkupViewController(
      markup: markup,
      supportedFeatureSet: featureSet
    )
    
    self.controller = controller
    
    // HDR support
    featureSet.colorMaximumLinearExposure = 4
    toolPicker.colorMaximumLinearExposure = 4
    
    // 확대는 8배까지(유튜브가 8배 zoom), 축소는 1배 미만 불가
    controller.zoomRange = 1.0 ... 8.0
    
    controller.view.backgroundColor = UIColor(Color.fillAssitive) // FIXME: - 컬러 수정
    

    // 초기 이미지 있으면 먼저 캔버스에 올리기 (initiakize)
    if let image {
      let targetRect = aspectFitRect(for: image.size, in: rect)
      insertImage(image, rect: targetRect)
    }
  }
  
  
  
  /// 이미지 비율 유지하면서 rect 안에 맞춰 넣는 유틸
  private func aspectFitRect(for imageSize: CGSize, in boundingRect: CGRect) -> CGRect {
    let widthScale  = boundingRect.width / imageSize.width
    let heightScale = boundingRect.height / imageSize.height
    let scale = min(widthScale, heightScale)
    
    let scaledSize = CGSize(
      width: imageSize.width * scale,
      height: imageSize.height * scale
    )
    
    let origin = CGPoint(
      x: boundingRect.midX - scaledSize.width / 2,
      y: boundingRect.midY - scaledSize.height / 2
    )
    
    return CGRect(origin: origin, size: scaledSize)
  }
  
  /// 되돌리기
  func undo() {
    controller?.undoManager?.undo()
  }
  
  /// 앞으로 가기
  func redo() {
    controller?.undoManager?.redo()
  }
  
  // MARK: - Markup Editing Methods
  /// 텍스트 삽입
  func insertText(_ text: NSAttributedString, rect: CGRect) {
    guard var markup = controller?.markup else { return }
    markup.insertNewTextbox(attributedText: text, frame: rect)
    controller?.markup = markup
  }
  
  /// 이미지 삽입
  func insertImage(_ image: UIImage, rect: CGRect) {
    guard
      let cgImage = image.cgImage,
      var markup = controller?.markup
    else { return }
    
    markup.insertNewImage(cgImage, frame: rect)
    controller?.markup = markup
  }
  
  /// 팬슬 킷 툴
  func showPencilKitTools(_ isVisible: Bool) {
    guard let controller else { return }
    
    toolPicker.addObserver(controller)
    toolPicker.setVisible(isVisible, forFirstResponder: controller.view)
    
    if isVisible {
      controller.view.becomeFirstResponder()
    }
  }
  
  /// 이미지 반환
  func exportAsImage(
    scale: CGFloat,
    backgroundColor: UIColor? = nil
  ) async -> UIImage? {
    guard
      let controller,
      let markup = controller.markup,
      let context = makeCGContext(size: markup.bounds.size, scale: scale)
    else {
      return nil
    }
    
    let frame = markup.bounds
    
    // 먼저 배경을 꽉 채워서 칠해준다
    if let bg = backgroundColor {
      context.saveGState()
      context.setFillColor(bg.cgColor)
      context.fill(CGRect(origin: .zero, size: frame.size))
      context.restoreGState()
    }
    
    // 그 위에 PaperKit(이미지 + 펜슬 드로잉) 렌더
    await markup.draw(in: context, frame: frame)
    
    guard let cgImage = context.makeImage() else {
      return nil
    }
    return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
  }
  
  // MARK: - CGContext 생성
  private func makeCGContext(size: CGSize, scale: CGFloat) -> CGContext? {
    let width  = Int(size.width * scale)
    let height = Int(size.height * scale)

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    guard let context = CGContext(
      data: nil,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: colorSpace,
      bitmapInfo: bitmapInfo
    ) else {
      return nil
    }

    // IKit(위에서 아래로 Y+) ↔ CoreGraphics(아래에서 위로 Y+) 맞춰주기
    context.translateBy(x: 0, y: size.height * scale) //  좌표계를 캔버스 높이만큼 올리고
    context.scaleBy(x: scale, y: -scale) // y축을 반전시킨 다음 (위아래 뒤집기)

    return context
  }
}


/// Calculating center rect with the given rect
extension NSAttributedString {
  func centerRect(in rect: CGRect) -> CGRect {
    let textSize = self.size()
    let textCenter = CGPoint(
      x: rect.midX - (textSize.width / 2),
      y: rect.midY - (textSize.height / 2)
    )
    
    return CGRect(
      origin: textCenter,
      size: textSize
    )
  }
}

