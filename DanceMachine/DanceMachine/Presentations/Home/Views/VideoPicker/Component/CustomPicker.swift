//
//  CustomPicker.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/6/25.
//

import SwiftUI
import Photos

struct CustomPicker: View {
  
  @Binding var videos: [PHAsset]
  @Binding var selectedAsset: PHAsset?
  
  let spacing: CGFloat
  let itemWidth: CGFloat
  
  var body: some View {
    LazyVGrid(
      columns: [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
      ],
      spacing: spacing
    ) {
      ForEach(videos, id: \.localIdentifier) { asset in
        VideoThumbnailCell(
          asset: asset,
          isSelected:
            selectedAsset?.localIdentifier == asset.localIdentifier,
          size: itemWidth
        )
          .onTapGesture {
            print("\(itemWidth)")
            selectedAsset = asset
          }
      }
    }
  }
}

#Preview {
  CustomPicker(videos: .constant([]), selectedAsset: .constant(PHAsset()), spacing: 1, itemWidth: 100)
}
