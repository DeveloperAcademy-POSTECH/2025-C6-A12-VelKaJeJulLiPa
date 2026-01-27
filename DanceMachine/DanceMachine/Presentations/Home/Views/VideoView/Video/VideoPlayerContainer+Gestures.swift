//
//  VideoPlayerContainer+Gestures.swift
//  DanceMachine
//
//  Created by Claude on 11/23/25.
//

import SwiftUI

extension VideoPlayerContainer {
  /// 비디오 확대/축소 제스처
  var magnificationGesture: some Gesture {
    MagnificationGesture()
      .onChanged { value in
        let newScale = zoomScale * value

        // 1.0 ~ 8.0 범위로 제한
        if newScale < 1.0 {
          currentZoom = 1.0 / zoomScale
          // 1.0 미만으로 축소 시도 시 햅틱 (한 번만)
          if !hasTriggeredMinHaptic {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            hasTriggeredMinHaptic = true
          }
        } else if newScale > 8.0 {
          currentZoom = 8.0 / zoomScale
          // 8.0 초과 확대 시도 시 햅틱 (한 번만)
          if !hasTriggeredMaxHaptic {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            hasTriggeredMaxHaptic = true
          }
        } else {
          currentZoom = value
          // 범위 내로 돌아오면 햅틱 플래그 리셋
          hasTriggeredMinHaptic = false
          hasTriggeredMaxHaptic = false
        }

        // 확대/축소 중에도 현재 위치 기준으로 오프셋 실시간 조정
        // currentZoom이 변할 때마다 lastOffset을 currentZoom 비율만큼 조정
        offset = CGSize(
          width: lastOffset.width * currentZoom,
          height: lastOffset.height * currentZoom
        )

        if !showZoomIndicator {
          withAnimation(.easeInOut(duration: 0.2)) {
            showZoomIndicator = true
          }
        }
      }
      .onEnded { value in
        let previousScale = zoomScale
        zoomScale *= currentZoom
        currentZoom = 1.0

        // 범위 제한 및 1.0일 때 위치 리셋
        if zoomScale <= 1.0 {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            zoomScale = 1.0
            offset = .zero
            lastOffset = .zero
          }
        } else if zoomScale > 8.0 {
          zoomScale = 8.0
          // 스케일 변화에 따라 오프셋 조정 (현재 위치 유지)
          let scaleFactor = 8.0 / previousScale
          offset = CGSize(
            width: lastOffset.width * scaleFactor,
            height: lastOffset.height * scaleFactor
          )
          lastOffset = offset
        } else {
          // 스케일 변화에 따라 오프셋 조정 (현재 위치 유지)
          let scaleFactor = zoomScale / previousScale
          offset = CGSize(
            width: lastOffset.width * scaleFactor,
            height: lastOffset.height * scaleFactor
          )
          lastOffset = offset
        }

        // 햅틱 플래그 리셋
        hasTriggeredMinHaptic = false
        hasTriggeredMaxHaptic = false

        // 인디케이터 자동 숨김
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
          withAnimation(.easeInOut(duration: 0.2)) {
            showZoomIndicator = false
          }
        }
      }
  }

  /// 비디오 드래그 제스처 (확대 시 이동, 미확대 시 전체화면 전환)
  var dragGesture: some Gesture {
    DragGesture(minimumDistance: zoomScale > 1.0 ? 0 : 30)
      .onChanged { value in
        if zoomScale > 1.0 {
          // 확대됨: 화면 이동 (실시간) - 이전 위치에 현재 드래그 추가
          offset = CGSize(
            width: lastOffset.width + value.translation.width,
            height: lastOffset.height + value.translation.height
          )
        } else {
          // 확대 안 됨: 전체화면 전환
          if isIPad {
            onDragChanged?(value)
          } else {
            if isLandscapeMode {
              if value.translation.height > 0 {
                onDragChanged?(value)
              }
            } else {
              if value.translation.height < 0 {
                onDragChanged?(value)
              }
            }
          }
        }
      }
      .onEnded { value in
        if zoomScale > 1.0 {
          // 확대 상태: 현재 오프셋을 저장
          lastOffset = offset
        } else {
          // 전체화면 전환
          if isIPad {
            onDragEnded?(value)
          } else {
            if isLandscapeMode {
              if value.translation.height > 0 {
                onDragEnded?(value)
              }
            } else {
              if value.translation.height < 0 {
                onDragEnded?(value)
              }
            }
          }
        }
      }
  }
}
