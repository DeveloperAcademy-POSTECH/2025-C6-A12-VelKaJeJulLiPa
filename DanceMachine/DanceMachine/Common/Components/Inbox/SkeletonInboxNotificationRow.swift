//
//  SkeletonInboxNotificationRow.swift
//  DanceMachine
//
//  Created by Paidion on 11/18/25.
//

import SwiftUI

struct SkeletonInboxNotificationRow: View {
  var body: some View {
    VStack {
      skeletonRow
    }
    .frame(height: 153)
    .frame(maxWidth: .infinity)
    .background(
      Color.clear
    )
  }
  
  private var skeletonRow: some View {
    HStack(spacing: 8) {
      VStack() {
        SkeletonView(
          RoundedRectangle(cornerRadius: 5),
          .fillNormal
        )
        .frame(width: 22)
        .frame(height: 22)
        Spacer()
      }
      
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          SkeletonView(
            RoundedRectangle(cornerRadius: 5),
            .fillNormal
          )
          .frame(width: 92)
          .frame(height: 17)
          
          Spacer()
          
          SkeletonView(
            RoundedRectangle(cornerRadius: 5),
            .fillNormal
          )
          .frame(width: 58)
          .frame(height: 17)
        }
        
        VStack(spacing: 8) {
          SkeletonView(
            RoundedRectangle(cornerRadius: 5),
            .fillNormal
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          
          SkeletonView(
            RoundedRectangle(cornerRadius: 5),
            .fillNormal
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
    }
    .padding(.vertical, 24)
    .padding(.horizontal, 16)
  }
  
  
}

#Preview {
  SkeletonInboxNotificationRow()
}
