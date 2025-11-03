//
//  UploadProgressCard.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/3/25.
//

import SwiftUI

struct UploadProgressCard: View {
  let cardSize: CGFloat
  let progress: Double
  
  private var safeProgress: Double {
    guard progress.isFinite, progress >= 0, progress <= 1 else {
      return 0.0
    }
    return progress
  }

  var body: some View {
    ZStack(alignment: .top) {
      SkeletonCardView(cardSize: cardSize)
      circleProgressView
        .offset(y: cardSize * 0.15)
    }
  }
  
  private var circleProgressView: some View {
    VStack {
      ZStack {
        Circle()
          .stroke(
            Color.white.opacity(0.3),
            lineWidth: 4
          )
          .frame(
            width: cardSize / 2.5,
            height: cardSize / 2.5
          )
        Circle()
          .trim(from: 0, to: progress)
          .stroke(
            LinearGradient( // FIXME: 컬러 수정
              colors: [Color.blue, Color.purple],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            style: StrokeStyle(
              lineWidth: 4,
              lineCap: .round
            )
          )
          .frame(
            width: cardSize / 2.5,
            height: cardSize / 2.5
          )
          .rotationEffect(.degrees(90))
          .animation(.easeInOut, value: progress)
        
        VStack(spacing: 2) {
          Image(systemName: "arrow.up.circle.fill")
            // FIXME: 아이콘 수정
            .foregroundStyle(.purple.opacity(0.7))
          Text("\(Int(safeProgress * 100))%")
            .font(.system(size: 14)) // FIXME: 폰트 수정
            .foregroundStyle(.purple.opacity(0.7)) // FIXME: 컬러 수정
        }
      }
//      Spacer()
    }
//    .frame(width: cardSize, height: cardSize * 1.22)
  }
}

#Preview {
  UploadProgressCard(
    cardSize: 170,
    progress: 0.25
  )
}
