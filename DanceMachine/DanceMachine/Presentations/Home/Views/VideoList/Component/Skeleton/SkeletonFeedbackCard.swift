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
    .frame(height: 175)
    .frame(maxWidth: .infinity)
    .background(
      Color.clear
    )
  }
  
  private var card: some View {
    VStack(alignment: .leading) {
      SkeletonView(
        RoundedRectangle(cornerRadius: 5),
        .fillNormal
      )
        .frame(maxWidth: .infinity)
        .frame(height: 17)
        .padding(.trailing, 320)
      HStack {
        SkeletonView(
          RoundedRectangle(cornerRadius: 5),
          .fillNormal
        )
          .frame(maxWidth: .infinity)
          .frame(height: 17)
        SkeletonView(
          RoundedRectangle(cornerRadius: 5),
          .fillNormal
        )
          .frame(maxWidth: .infinity)
          .frame(height: 17)
        Spacer()
      }
      .padding(.trailing, 200)
      SkeletonView(
        RoundedRectangle(cornerRadius: 5),
        .fillNormal
      )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      HStack {
        Spacer()
        SkeletonView(
          RoundedRectangle(cornerRadius: 5),
          .fillNormal
        )
          .frame(width: 30)
          .frame(height: 19)
      }
    }
    .padding(.vertical, 16)
    .padding(.horizontal, 8)
  }
}

#Preview {
  SkeletonFeedbackCard()
}
