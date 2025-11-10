//
//  downloadProgress.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/9/25.
//

import SwiftUI

struct downloadProgress: View {
  let progress: Double
  
  var body: some View {
    VStack {
      ZStack {
        Circle()
          .stroke(
            Color.fillAssitive,
            lineWidth: 5
          )
          .frame(
            width: 60,
            height: 60
          )
        Circle()
          .trim(from: 0, to: progress)
          .stroke(
            Color.secondaryNormal,
            style: StrokeStyle(
              lineWidth: 5,
              lineCap: .round
            )
          )
          .frame(width: 60, height: 60)
          .rotationEffect(.degrees(90))

        VStack(spacing: 2) {
          Image(systemName: "arrowshape.up.fill")
            .font(.system(size: 20))
            .foregroundStyle(Color.secondaryNormal)
            .rotationEffect(Angle(degrees: 180))
          Text("\(Int(progress * 100))%")
            .font(.system(size: 14))
            .foregroundStyle(Color.secondaryNormal)
        }
      }
    }
  }
}

#Preview {
  downloadProgress(progress: 0.2)
}
