//
//  GridCell.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/15/25.
//

import SwiftUI

struct GridCell: View {
  var size: CGFloat

  let videoId: String // 썸네일 캐싱용
  let thumbnailURL: String?
  let title: String
  let duration: Double
  let uploadDate: Date

  let editAction: () -> Void
  let deleteAction: () -> Void
  let showEditSheet: () -> Void
  
  let videoAction: () -> Void
  
  let sectionCount: Int
  
  @State private var showMenu: Bool = false
  
  var body: some View {
    VStack(alignment: .leading) {
      thumbnail
      content
    }
    .frame(width: size, height: size * 1.22)
    .contentShape(Rectangle())
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(.fillNormal)
    )
    .sensoryFeedback(.success, trigger: showMenu)
    .onTapGesture { videoAction() }
    .overlay(alignment: .topTrailing) {
      Menu {
        contextRow
      } label: {
        Image(systemName: "elipsis")
          .foregroundStyle(.red)
          .rotationEffect(.degrees(90))
          .frame(width: 44, height: 44)
      }
    }
    .contextMenu {
      contextRow
        .preferredColorScheme(.dark)  // 강제 다크모드
    }
    .preferredColorScheme(.dark)  // 강제 다크모드
  }
  
  private var content: some View {
    VStack(alignment: .leading) {
      Text(title)
        .font(.headline2Medium)
        .foregroundStyle(.labelStrong)
      Spacer().frame(height: 8)
      Text("\(duration.formattedTime())")
        .font(.caption1Medium)
        .foregroundStyle(.labelAssitive)
      Spacer().frame(height: 4)
      Text("\(uploadDate.formattedDate())")
        .font(.caption1Medium)
        .foregroundStyle(.labelAssitive)
      Spacer().frame(height: 16)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.top, 8)
    .padding(.horizontal, 8)
  }
  
  private var thumbnail: some View {
    VStack {
      if let url = thumbnailURL {
        ThumbnailAsyncImage(
          thumbnailURL: url,
          videoId: videoId,
          size: size,
          height: size / 1.5
        )
      }
    }
  }
  
  private var contextRow: some View {
    VStack(alignment: .leading, spacing: 16) {
      Button {
        showEditSheet()
      } label: {
        HStack {
          Image(systemName: "pencil")
            .tint(.labelStrong)
          Text("이름 수정")
            .font(.headline1Medium)
        }
      }

      Button {
        editAction()
      } label: {
        HStack {
          Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
            .tint(sectionCount <= 1 ? Color.fillAssitive : Color.labelStrong)
          Text("다른 파트로 이동")
            .font(.headline1Medium)
        }
      }
      .disabled(sectionCount <= 1)

      Button(role: .destructive) {
        deleteAction()
      } label: {
        HStack {
          Image(systemName: "trash")
            .tint(.accentRedStrong)
          Text("영상 삭제")
        }
      }
    }
  }
}


#Preview {
  GridCell(
    size: 172,
    videoId: "",
    thumbnailURL: "https://picsum.photos/300",
    title: "제목",
    duration: 14.1414141414,
    uploadDate: Date(),
    editAction: {},
    deleteAction: {},
    showEditSheet: {},
    videoAction: {},
    sectionCount: 0
  )
}
