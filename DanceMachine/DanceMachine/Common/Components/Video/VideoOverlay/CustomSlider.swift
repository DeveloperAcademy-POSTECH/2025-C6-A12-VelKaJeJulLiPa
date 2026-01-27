//
//  CustomSlider.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/27/25.
//

import SwiftUI
import DancePoseAnalysis

struct CustomSlider: View {
  @Binding var isDragging: Bool
  
  let currentTime: Double
  let duration: Double
  let onSeek: (Double) -> Void
  let onDragChanged: (Double) -> Void
  
  let startTime: String
  let endTime: String
  
  var progress: Double {
    guard duration > 0 else { return 0 }
    return currentTime / duration
  }
  
  var body: some View {
    VStack {
      Spacer()
      GeometryReader { g in
        ZStack(alignment: .leading) {
          // 배경 바
          backgroundBar
          // 진행 바
          progressBar(g: g)
          // 슬라이더 핸들 (마커보다 위에 표시
          sliderHandle(g: g)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(sliderDragGesture(totalWidth: g.size.width))
      }
      .frame(height: 25)
      .contentShape(Rectangle())
      // 하단 시간
      time
        .padding(.bottom, 10)
    }
  }
  // 배경 바
  private var backgroundBar: some View {
    Rectangle()
      .fill(Color.labelStrong.opacity(0.6))
      .frame(height: 4)
      .clipShape(RoundedRectangle(cornerRadius: 2))
  }
  // 진행 바
  private func progressBar(g: GeometryProxy) -> some View {
    Rectangle()
      .fill(Color.secondaryStrong)
      .frame(width: progressWidth(g.size.width), height: 4)
      .clipShape(RoundedRectangle(cornerRadius: 2))
  }
  // 슬라이더 핸들 (마커보다 위에 표시
  private func sliderHandle(g: GeometryProxy) -> some View {
    Circle()
      .fill(Color.labelStrong)
      .frame(
        width: isDragging ? 25 : 20,
        height: isDragging ? 25 : 20
      )
      .contentShape(Circle())
      .offset(
        x: progressWidth(g.size.width) -
        (isDragging ? 10 : 5)
      )
  }
  // 하단 시간
  private var time: some View {
    HStack {
      Text(startTime)
        .font(.caption1Medium)
        .foregroundStyle(.labelStrong)
      Spacer()
      Text(endTime)
        .font(.caption1Medium)
        .foregroundStyle(.labelStrong)
    }
  }
  // 공통 제스처 함수
  private func sliderDragGesture(totalWidth: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        isDragging = true
        let p = min(max(0, value.location.x / totalWidth), 1)
        let new = p * duration
        onDragChanged(new)
      }
      .onEnded { value in
        let p = min(max(0, value.location.x / totalWidth), 1)
        let new = p * duration
        onSeek(new)
        DispatchQueue.main.asyncAfter(deadline: .now()) {
          isDragging = false
        }
      }
  }
  
  private func progressWidth(_ totalWidth: CGFloat) -> CGFloat {
    return progress * totalWidth
  }
}

#Preview {
  CustomSlider(
    isDragging: .constant(true),
    currentTime: 10.00,
    duration: 20.00,
    onSeek: {_ in },
    onDragChanged: {_ in },
    startTime: "22",
    endTime: "222",
  )
}
