//
//  SkeletonFeedbackCard.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/4/25.
//

import SwiftUI

struct SkeletonFeedbackCard: View {
  var body: some View {
    VStack {
      card
    }
    .frame(height: 132)
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: 15)
        .fill(Color.gray.opacity(0.3))
    )
  }
  
  private var card: some View {
    VStack(alignment: .leading) {
      SkeletonView(RoundedRectangle(cornerRadius: 5))
        .frame(width: 82, height: 17)
      HStack {
        SkeletonView(RoundedRectangle(cornerRadius: 5))
          .frame(width: 118, height: 19)
        SkeletonView(RoundedRectangle(cornerRadius: 5))
          .frame(width: 51, height: 19)
      }
      SkeletonView(RoundedRectangle(cornerRadius: 5))
        .frame(width: 345, height: 52)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 10)
  }
}

#Preview {
  SkeletonFeedbackCard()
}
