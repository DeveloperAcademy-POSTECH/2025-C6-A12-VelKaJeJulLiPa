//
//  FeedbackPencilDrawingView.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/13/25.
//

import SwiftUI
import PencilKit
import AVFoundation

/// iOS 26 미만 대체용 드로잉 오버레이
/// - image: 반드시 받아야 하는 원본 배경 이미지
/// - onDone: 합성 완료 이미지 콜백
/// - onCancel: 취소 콜백(선택)
struct FeedbackPencilDrawingView: View {
  
  @Environment(\.dismiss) private var dismiss
  
  @Binding var image: UIImage?
  
  var onDone: (UIImage) -> Void = { _ in }
  var onCancel: (() -> Void)? = nil
  
  @State private var canvasView = PKCanvasView()
  @State private var selectedTool: PKTool = PKInkingTool(.pen, color: UIColor(Color.labelStrong), width: 5) // 초기 팬슬 설정
  @State private var showsToolPicker: Bool = false
  
  private let toolPicker = PKToolPicker()
  
  var body: some View {
    GeometryReader { geo in
      ZStack {
        Color.backgroundNormal.ignoresSafeArea()
        VStack(spacing: 4) {
          drawingToolbar.padding(.horizontal, 16)
          PencilCanvasView(
            canvasView: $canvasView,
            tool: selectedTool,
            image: image
          )
          .frame(width: geo.size.width, height: geo.size.height)
          .contentShape(Rectangle())
        }
      }
    }
    .onAppear {
      configureToolPicker()
      updateToolPickerVisibility(showsToolPicker)
    }
    // 토글될 때마다 실제로 툴피커 갱신
    .onChange(of: showsToolPicker) { old, visible in
      updateToolPickerVisibility(visible)
    }
  }
  
  /// 피커의 변경 사항을 알려주는 관찰 메서드 입니다.
  private func configureToolPicker() {
    toolPicker.addObserver(canvasView)
  }
  
  /// PKToolPicker 표시 상태를 안전하게 전환한다.
  ///
  /// 기능
  /// - `canvasView.window == nil`(아직 뷰 계층에 붙지 않음) 이면, 다음 런루프에 동일한 인자를 보존해 재시도한다.
  /// - `toolPicker.setVisible(_:forFirstResponder:)`를 사용해 피커 표시/비표시를 전환한다.
  /// - 표시할 때는 `canvasView.becomeFirstResponder()`로 포커스를 가져오고,
  ///   숨길 때는 `canvasView.resignFirstResponder()`로 포커스를 반환한다.
  /// - UI 작업이므로 `@MainActor`에서 실행된다.
  ///
  /// 예시
  /// ```swift
  /// .onChange(of: showsToolPicker) { _, newValue in
  ///   await updateToolPickerVisibility(newValue)
  /// }
  /// ```
  @MainActor
  private func updateToolPickerVisibility(_ visible: Bool) {
    // 아직 윈도우에 안 붙었으면 다음 런루프에서 재시도
    guard canvasView.window != nil else {
      DispatchQueue.main.async { [visible] in
        updateToolPickerVisibility(visible)
      }
      return
    }
    
    toolPicker.setVisible(visible, forFirstResponder: canvasView)
    if visible {
      canvasView.becomeFirstResponder()
    } else {
      canvasView.resignFirstResponder()
    }
  }
  
  // MARK: - 탑 타이틀
  private var drawingToolbar: some View {
    LabeledContent {
      HStack(spacing: 16) {
        // 되돌리기
        Button {
          undoDrawing()
        } label: {
          Image(systemName: "arrow.uturn.backward")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(Color.labelStrong)
        }
        
        /// 앞으로 가기
        Button {
          redoDrawing()
        } label: {
          Image(systemName: "arrow.uturn.forward")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(Color.labelStrong)
        }
        
        
        // 팬슬 툴
        Button {
          showsToolPicker.toggle()
        } label: {
          if showsToolPicker {
            Image(systemName: "pencil.circle.fill")
              .resizable()
              .scaledToFit()
              .frame(width: 24, height: 24)
              .foregroundStyle(Color.labelStrong)
          }
          else {
            Image(systemName: "pencil.circle")
              .resizable()
              .scaledToFit()
              .frame(width: 24, height: 24)
              .foregroundStyle(Color.labelStrong)
          }
        }
        
        
        // 완료 버튼
        Button {
          if let merged = exportMergedImageOnscreenSize() {
            onDone(merged)
            dismiss()
          }
        } label: {
          Image(systemName: "checkmark.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(Color.labelStrong)
        }
        
      }
    } label: {
      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark.circle.fill")
          .resizable()
          .frame(width: 24, height: 24) // FIXME: - 크기 수정
          .foregroundStyle(Color.labelStrong)
      }
    }
    .font(.headline)
    .foregroundStyle(.black)
  }
  
  /// 팬슬 이전 그림 취소하는 기능입니다.
  private func undoDrawing() {
    guard let manager = canvasView.undoManager else { return } // FIXME: - 에러 처리 추가
    if manager.canUndo { manager.undo() }
  }
  
  /// 팬슬 앞으로  그림으로 돌아가는 기능입니다.
  private func redoDrawing() {
    guard let manager = canvasView.undoManager else { return } // FIXME: - 에러 처리 추가
    if manager.canUndo { manager.redo() }
  }
  
  /// 캔버스에 그린 그림을 UIImage로 리턴하는 메서드입니다.
  private func exportMergedImageOnscreenSize() -> UIImage? {
    
    guard let image = image else { return nil }
    
    let canvasSize = canvasView.bounds.size
    guard canvasSize.width > 0, canvasSize.height > 0 else { return nil }
    
    let rect = CGRect(origin: .zero, size: canvasSize)
    
    let renderer = UIGraphicsImageRenderer(size: canvasSize)
    
    return renderer.image { _ in
      // 1) 배경 이미지를 캔버스 크기 안에 aspectFit으로 그림
      let fit = AVMakeRect(aspectRatio: image.size, insideRect: rect)
      image.draw(in: fit)
      // 2) 드로잉 오버레이(캔버스 좌표계 그대로)
      let overlay = canvasView.drawing.image(from: rect, scale: UIScreen.main.scale)
      overlay.draw(in: rect)
    }
  }
}

//#Preview {
//  // 프리뷰용 이미지가 없으면 시스템 심볼로 대체
//  let demo = UIImage(systemName: "photo")!.withTintColor(.gray, renderingMode: .alwaysOriginal)
//  return A(image: demo)
//}

