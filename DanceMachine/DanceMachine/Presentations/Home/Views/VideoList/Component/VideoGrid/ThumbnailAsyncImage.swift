//
//  ThumbnailAsyncImage.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/15/25.
//

import SwiftUI
import Kingfisher

struct ThumbnailAsyncImage: View {
  let thumbnailURL: String?
  let videoId: String // 캐시 키
  
  var size: CGFloat?
  var height: CGFloat?
  
  @State private var isLoading: Bool = false
  @State private var cachedImage: UIImage? = nil
  
  var body: some View {
    Group {
      if let urlString = thumbnailURL,
          let url = URL(string: urlString) {
        KFImage(url)
          .placeholder { thumbnailSkeletonView }
          .retry(maxCount: 3, interval: .seconds(0.5))
          .onFailure { error in print("썸네일 로드 실패") }
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: size, height: height)
          .clipped()
          .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))
      } else { defaultImageView }
    }
  }

  private var thumbnailSkeletonView: some View {
    SkeletonView(
      RoundedRectangle(cornerRadius: 10)
    )
  }
  
  private var defaultImageView: some View {
    Rectangle()
      .aspectRatio(contentMode: .fill)
      .frame(width: size, height: height)
      .clipped()
      .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))
      .overlay {
        Image(systemName: "photo")
          .font(.title3)
          .foregroundStyle(.gray)
      }
  }
}

#Preview {
  ThumbnailAsyncImage(thumbnailURL: nil, videoId: "", size: 179, height: 96)
}
