//
//  ThumbnailAsyncImage.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/15/25.
//

import SwiftUI

struct ThumbnailAsyncImage: View {
  let thumbnailURL: String?
  let videoId: String // 캐시 키
  
  var size: CGFloat?
  var height: CGFloat?
  
  @State private var isLoading: Bool = false
  @State private var cachedImage: UIImage? = nil
  
  var body: some View {
    Group {
      if let cached = cachedImage {
        Image(uiImage: cached)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .clipShape(RoundedRectangle(cornerRadius: 10))
      } else if let url = thumbnailURL, let url = URL(string: url) {
        AsyncImage(url: url) { i in
          i
            .resizable()
            .aspectRatio(contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onAppear {
              Task {
                if let uiImage = await loadUIImage(from: url),
                    let url = thumbnailURL {
                  _ = try await VideoCacheManager.shared.downloadAndCacheThumbnail(
                    from: url,
                    videoId: videoId
                  )
                }
              }
            }
        } placeholder: {
          thumbnailSkeletonView
        }
      } else {
        defaultImageView
      }
    }
    .frame(width: size, height: height)
    .clipped()
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .task {
      cachedImage = await VideoCacheManager.shared.getCachedThumbnailURL(
        for: videoId
      )
    }
  }

  private var thumbnailSkeletonView: some View {
    SkeletonView(
      RoundedRectangle(cornerRadius: 10)
    )
  }
  
  private var defaultImageView: some View {
    Rectangle()
      .fill(Color.gray.opacity(0.3))
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .overlay {
        Image(systemName: "photo")
          .font(.title3)
          .foregroundStyle(.gray)
      }
  }
  
  private func loadUIImage(from url: URL) async -> UIImage? {
    guard let (data, _) = try? await URLSession.shared.data(from: url),
          let image = UIImage(data: data) else {
      return nil
    }
    return image
  }
}

#Preview {
  ThumbnailAsyncImage(thumbnailURL: "https://picsum.photos/300", videoId: "", size: 179, height: 96)
}
