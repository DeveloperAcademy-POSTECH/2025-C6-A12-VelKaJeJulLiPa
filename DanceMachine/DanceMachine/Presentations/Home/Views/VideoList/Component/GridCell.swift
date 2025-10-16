//
//  GridCell.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/15/25.
//

import SwiftUI

struct GridCell: View {
  var size: CGFloat
//  var height: CGFloat?
  
  let thumbnailURL: String?
  let title: String
  let duration: Double
  let uploadDate: Date
  
  var body: some View {
    Rectangle()
      .fill(Color.white)
      .frame(width: size, height: size * 1.2)
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .overlay {
        content
      }
  }
  
  private var content: some View {
    VStack(alignment: .leading) {
      thumbnail
      Spacer().frame(width: 8)
      Text(title)
      Spacer().frame(width: 8)
      Text("\(duration.formattedTime())")
      Spacer().frame(width: 4)
      Text("\(uploadDate.formattedDate())")
      
      Spacer()
    }
//    .padding(.leading, 4)
  }
  
  private var thumbnail: some View {
    VStack {
      if let url = thumbnailURL {
        ThumbnailAsyncImage(
          thumbnailURL: url,
          size: size,
          height: size / 1.5
        )
      }
    }
//    .padding(.leading, -4)
  }
}

#Preview {
  GridCell(
    size: 172,
    thumbnailURL: "https://picsum.photos/300",
    title: "제목",
    duration: 14.1414141414,
    uploadDate: Date()
  )
}
