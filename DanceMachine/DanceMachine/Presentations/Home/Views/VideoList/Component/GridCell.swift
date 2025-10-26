//
//  GridCell.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/15/25.
//

import SwiftUI

struct GridCell: View {
  var size: CGFloat
  
  let thumbnailURL: String?
  let title: String
  let duration: Double
  let uploadDate: Date
  
  let editAction: () -> Void
  let deleteAction: () -> Void
  
  let videoAction: () -> Void
  
  @State private var showMenu: Bool = false
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      Rectangle()
        .fill(Color.white)
        .frame(width: size, height: size * 1.2)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
          content
        }
        .sensoryFeedback(.success, trigger: showMenu)
        .onTapGesture {
          videoAction()
        }
    }
    .contextMenu {
      contextMenu
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
  }
  
  
  private var contextMenu: some View {
    RoundedRectangle(cornerRadius: 40)
      .fill(.ultraThinMaterial)
      .frame(width: 201)
      .frame(height: 120)
      .overlay {
        contextRow
      }
  }
  
  private var contextRow: some View {
    VStack(alignment: .leading, spacing: 16) {
      Button {
        editAction()
      } label: {
        HStack {
          Image(systemName: "pencil")
          Text("영상 이동")
        }
      }
      Button {
        deleteAction()
      } label: {
        HStack {
          Image(systemName: "trash")
          Text("영상 삭제")
        }
      }
    }
  }
}


#Preview {
  GridCell(
    size: 172,
    thumbnailURL: "https://picsum.photos/300",
    title: "제목",
    duration: 14.1414141414,
    uploadDate: Date(),
    editAction: {},
    deleteAction: {},
    videoAction: {}
  )
}
