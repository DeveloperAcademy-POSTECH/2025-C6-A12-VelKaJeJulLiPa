//
//  ThumbnailAsyncImage.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/15/25.
//

import SwiftUI

struct ThumbnailAsyncImage: View {
  let thumbnailURL: String?
  
  var size: CGFloat?
  var height: CGFloat?
  
  @State private var isLoading: Bool = false
  
  var body: some View {
    Group {
      if let url = thumbnailURL,
          let url = URL(string: url) {
        AsyncImage(url: url) { i in
          i
            .resizable()
            .aspectRatio(contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        } placeholder: {
          ProgressView()
        }
      } else if isLoading {
        ProgressView() // FIXME: 기본 로딩?
      } else {
        defaultImageView // FIXME: 썸네일 추출 실패했을 때 기본 이미지 (앱 로고 표시?)
      }
    }
    .frame(width: size, height: height)
    .clipped()
    .clipShape(RoundedRectangle(cornerRadius: 10))
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
}

#Preview {
  ThumbnailAsyncImage(thumbnailURL: "https://picsum.photos/300", size: 179, height: 96)
}
