//
//  GridCell.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/15/25.
//

import SwiftUI

struct GridCell: View { // FIXME: 디자인 수정!
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
    VStack(alignment: .leading) {
      thumbnail
      content.padding(.leading, 8)
    }
    .frame(width: size, height: size * 1.2)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.gray)
    )
    .sensoryFeedback(.success, trigger: showMenu)
    .onTapGesture { videoAction() }
    .contextMenu { contextRow }
    .overlay(alignment: .topTrailing) {
      Menu {
        contextRow
      } label: {
        Image(systemName: "ellipsis")
          .foregroundStyle(.white)
          .rotationEffect(.degrees(90))
          .frame(width: 44, height: 44)
      }
    }
  }
  
  private var content: some View {
    VStack(alignment: .leading) {
      Spacer().frame(width: 8)
      Text(title).foregroundStyle(.black)
      Spacer().frame(width: 8)
      Text("\(duration.formattedTime())").foregroundStyle(.black)
      Spacer().frame(width: 4)
      Text("\(uploadDate.formattedDate())").foregroundStyle(.black)
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
  // MARK: Menu 실행시 뜨는 Row
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
      Button(role: .destructive) {
        deleteAction()
      } label: {
        HStack {
          Image(systemName: "trash")
            .foregroundStyle(.red) // FIXME: 컬러 수정
          Text("영상 삭제")
            .foregroundStyle(.red) // FIXME: 컬러 수정
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
