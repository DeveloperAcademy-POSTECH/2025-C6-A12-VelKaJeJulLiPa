//
//  VideoViewState.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/21/25.
//

import Foundation
import SwiftUI
import AVKit

/// 비디오 화면  상태 관리
@Observable
final class VideoViewState {
  // MARK: - Feedback
  var showFeedbackInput: Bool = false
  var feedbackType: FeedbackType = .point
  var feedbackFilter: FeedbackFilter = .all
  var pointTime: Double = 0
  var intervalTime: Double = 0
  var scrollProxy: ScrollViewProxy? = nil
  
  // MARK: - Video Player
  var isDragging: Bool = false
  var sliderValue: Double = 0
  var showSpeedSheet: Bool = false
  
  // MARK: - Orientation
  var forceShowLandscape: Bool = false // 전체 화면 버튼으로 가는 가로모드
  var showFeedbackPanel: Bool = false
  var iPadShowFullScreen: Bool = false // iPad 전체화면 상태
  var dragOffset: CGFloat = 0
  
  // MARK: - Drawing
  var showFeedbackPaperDrawingView: Bool = false
  var capturedImage: UIImage? = nil
  var editedOverlayImage: UIImage? = nil
  var savedDrawingData: Data? = nil // PencilKit 드로잉 데이터
  var savedMarkupData: Data? = nil // PaperKit 마크업 데이터
  var backgroundImage: UIImage? = nil // 원본 캡처 이미지
  var isEditingExistingDrawing: Bool = false // 편집 모드 여부
  
  // MARK: - drawing Preview
  var showDrawingImageFull: Bool = false
  var selectedFeedbackImageURL: String? = nil
  var showFeedbackImageFull: Bool = false
  
  /// 이미지 확대 변수
  var isImageOverlayPresented: Bool {
    showDrawingImageFull || showFeedbackImageFull
  }
  
  // MARK: 드로잉 리셋
  func resetDrwaingData() {
    editedOverlayImage = nil
    savedDrawingData = nil
    savedMarkupData = nil
    backgroundImage = nil
    isEditingExistingDrawing = false
  }
}

extension VideoViewState {
  @MainActor
  func enterLandscapeMode() {
    // iPad: UI만 전환 (기기 회전 없음)
    // iPhone: 기기 회전 + UI 전환
    if UIDevice.current.userInterfaceIdiom == .phone {
      AppDelegate.orientationMask = .landscape

      guard let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first else { return }

      scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
      scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
    }

    forceShowLandscape = true
  }

  @MainActor
  func exitLandscapeMode() {
    // iPad: UI만 전환 (기기 회전 없음)
    // iPhone: 기기 회전 + UI 전환
    if UIDevice.current.userInterfaceIdiom == .phone {
      AppDelegate.orientationMask = .portrait

      guard let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first else { return }

      scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
      scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
    }

    forceShowLandscape = false
  }
}
