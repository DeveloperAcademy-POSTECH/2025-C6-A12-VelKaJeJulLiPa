//
//  SkeletonCardView.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/2/25.
//

import SwiftUI

struct SkeletonCardView: View {
  let cardSize: CGFloat
  
  var body: some View {
    VStack(alignment: .leading) {
      thumbnail
      content
      Spacer()
    }
    .frame(
      width: cardSize,
      height: cardSize * 1.22
    )
    .background(
      RoundedRectangle(cornerRadius: 10)
        .fill(Color.fillAssitive)
    )
    .clipShape(RoundedRectangle(cornerRadius: 5))
  }
  
  private var thumbnail: some View {
    VStack {
      topSkeletonView
        .frame(
          width: cardSize,
          height: cardSize / 1.5
        )
    }
  }
  
  private var content: some View {
    VStack(alignment: .leading) {
      
      bottomSkeletonView
        .frame(width: cardSize * 0.7, height: 20)
//      Spacer().frame(width: 8)
      bottomSkeletonView
        .frame(width: cardSize * 0.3, height: 16)
//      Spacer().frame(width: 4)
      bottomSkeletonView
        .frame(width: cardSize * 0.5, height: 15)
//      Spacer()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.top, 8)
    .padding(.horizontal, 8)
  }
  
  private var topSkeletonView: some View {
    SkeletonView(
      RoundedCorner(radius: 10, corners: [.topLeft, .topRight]),
      Color.fillNormal
    )
  }
  
  private var bottomSkeletonView: some View {
    SkeletonView(
      RoundedRectangle(cornerRadius: 5),
      Color.fillNormal
    )
  }
}

#Preview {
  SkeletonCardView(
    cardSize: 172
  )
}
