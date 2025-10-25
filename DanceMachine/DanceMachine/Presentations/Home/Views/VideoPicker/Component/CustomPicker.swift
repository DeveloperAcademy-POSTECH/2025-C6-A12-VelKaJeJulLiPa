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
#if DEBUG
      if ProcessInfo.processInfo.environment ["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
        ForEach(0..<24, id: \.self) { _ in
          VideoThumbnailCell_Preview()
            .frame(width: itemWidth, height: itemWidth)
        }
      } else {
        ForEach(videos, id: \.localIdentifier) { asset in
          VideoThumbnailCell(
            asset: asset,
            isSelected:
              selectedAsset?.localIdentifier == asset.localIdentifier,
            size: itemWidth
          )
            .onTapGesture {
              selectedAsset = asset
            }
        }
      }
#else
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
#endif
    }
  }
}

#Preview {
  CustomPicker(videos: .constant([]), selectedAsset: .constant(PHAsset()), spacing: 1, itemWidth: 100)
}
