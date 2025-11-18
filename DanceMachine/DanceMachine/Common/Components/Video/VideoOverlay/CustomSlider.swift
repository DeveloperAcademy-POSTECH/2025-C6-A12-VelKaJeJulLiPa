//
//  CustomSlider.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/27/25.
//

import SwiftUI

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
          Rectangle()
            .fill(Color.labelStrong.opacity(0.6))
            .frame(height: 4)
            .clipShape(RoundedRectangle(cornerRadius: 2))
          
          Rectangle()
            .fill(Color.secondaryStrong)
            .frame(width: progressWidth(g.size.width), height: 4)
            .clipShape(RoundedRectangle(cornerRadius: 2))
          
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
            .gesture(
              DragGesture()
                .onChanged({ value in
                  isDragging = true
                  let p = min(max(0, value.location.x / g.size.width), 1)
                  let new = p * duration
                  onDragChanged(new)
                })
                .onEnded({ value in
                  let p = min(max(0, value.location.x / g.size.width), 1)
                  let new = p * duration
                  onSeek(new)
                  
                  DispatchQueue.main.asyncAfter(deadline: .now()) {
                    isDragging = false
                  }
                })
            )
        }
        .contentShape(Rectangle())
        .onTapGesture { location in
          let p = location.x / g.size.width
          let new = p * duration
          onSeek(new)
        }
        .animation(.easeIn(duration: 0.1), value: isDragging)
      }
      .frame(height: 25)
      .contentShape(Rectangle())
      HStack {
        Text(startTime)
          .font(.caption1Medium)
          .foregroundStyle(.labelStrong)
        Spacer()
        Text(endTime)
          .font(.caption1Medium)
          .foregroundStyle(.labelStrong)
      }
      .padding(.bottom, 10)
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
    endTime: "222"
  )
}
