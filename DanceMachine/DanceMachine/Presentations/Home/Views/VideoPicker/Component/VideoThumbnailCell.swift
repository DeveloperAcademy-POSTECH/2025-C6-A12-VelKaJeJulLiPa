//
//  VideoThumbnailCell.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/5/25.
//

import SwiftUI
import Photos

struct VideoThumbnailCell: View {
  let asset: PHAsset
  let isSelected: Bool
  
  var size: CGFloat
  
  @State private var thumbnail: UIImage?
  
  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      if let image = thumbnail {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: size, height: size)
          .clipped()
        duration
      } else {
        Rectangle()
          .fill(Color.gray.opacity(0.3))
      }
    }
    .frame(width: size, height: size)
    .contentShape(Rectangle())
    .task {
      await loadThumbnail()
    }
  }
  
  private var duration: some View {
    VStack {
      Text(formatDuration(asset.duration))
        .font(.caption2)
        .padding(4)
        .background(
          isSelected ? Color.purple : Color.black.opacity(0.7)
        )
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .padding(4)
    }
  }
  
  private func loadThumbnail() async {
    let manager = PHImageManager.default()
    let options = PHImageRequestOptions()
    options.isSynchronous = false
    options.deliveryMode = .opportunistic
    
    manager.requestImage(
      for: asset,
      targetSize: CGSize(width: 300, height: 300),
      contentMode: .aspectFill,
      options: options) { image, _ in
        self.thumbnail = image
      }
  }
  
  private func formatDuration(_ seconds: TimeInterval) -> String {
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return String(format: "%d:%02d", mins, secs)
  }
}

#Preview {
  VideoThumbnailCell_Preview()
}

struct VideoThumbnailCell_Preview: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
          VStack {
            Text("0:42")
              .font(.caption2)
              .padding(4)
              .background(Color.black.opacity(0.7))
              .foregroundColor(.white)
              .clipShape(RoundedRectangle(cornerRadius: 4))
              .padding(4)
          }
          .padding(.trailing, 20)
          .padding(.bottom, 20)
        }
//        .frame(width: 100, height: 100)
    }
}
