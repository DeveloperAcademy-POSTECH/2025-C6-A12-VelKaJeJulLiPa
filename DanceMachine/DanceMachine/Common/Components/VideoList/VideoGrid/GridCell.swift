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
  
  let currentUserId: String
  let videoUploaderId: String
  let editAction: () -> Void
  let deleteAction: () -> Void
  let showEditSheet: () -> Void
  let showCreateReportSheet: () -> Void
  
  let videoAction: () -> Void
  
  let sectionCount: Int

  @State private var showMenu: Bool = false
  @State private var isPressed: Bool = false

  var body: some View {
    VStack(alignment: .leading) {
      thumbnail
      content
    }
    .contentShape(Rectangle())
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(.fillNormal)
    )
    .scaleEffect(isPressed ? 0.97 : 1.0)
    .opacity(isPressed ? 0.8 : 1.0)
    .animation(.easeInOut(duration: 0.15), value: isPressed)
    .sensoryFeedback(.success, trigger: showMenu)
    .simultaneousGesture(
      DragGesture(minimumDistance: 0)
        .onChanged { value in
          let horizontal = abs(value.translation.width)
          let vertical = abs(value.translation.height)

          // 수평/수직 드래그 감지 (스크롤 허용)
          if horizontal > 10 || vertical > 10 {
            isPressed = false
            return
          }

          // 작은 움직임 - 탭으로 인식
          if !isPressed && !showMenu {
            isPressed = true
          }
        }
        .onEnded { _ in
          isPressed = false
        }
    )
    .simultaneousGesture(
      TapGesture()
        .onEnded {
          HapticManager.shared.trigger(.light)
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            videoAction()
          }
        }
    )
    .onChange(of: showMenu) { _, newValue in
      // contextMenu가 열리면 눌림 상태 해제
      if newValue {
        isPressed = false
      }
    }
    .overlay(alignment: .topTrailing) {
      Menu {
        contextRows
      } label: {
        Image(systemName: "ellipsis")
          .foregroundStyle(.labelStrong)
          .rotationEffect(.degrees(90))
          .frame(width: 33, height: 33)
          .simultaneousGesture(
            TapGesture()
              .onEnded {
                showMenu.toggle()
              }
          )
      }
    }
    .contextMenu {
      contextRows
        .preferredColorScheme(.dark)  // 강제 다크모드
    }
    .preferredColorScheme(.dark)  // 강제 다크모드
  }
  
  private var content: some View {
    VStack(alignment: .leading) {
      Spacer().frame(height: 8)
      Text(title)
        .font(.headline2Medium)
        .foregroundStyle(.labelStrong)
        .lineLimit(1)
        .truncationMode(.tail)
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
    .padding(.horizontal, 8)
  }
  
  private var thumbnail: some View {
    VStack {
      if let url = thumbnailURL {
        ThumbnailAsyncImage(
          thumbnailURL: url,
          videoId: videoId,
          size: size,
          height: size / 1.79
        )
      }
    }
  }
  
  private var contextRows: some View {
    VStack(alignment: .leading, spacing: 16) {
      if currentUserId == videoUploaderId {
        videoTitleEditButton
        videoEditButton
        deleteButton
      } else {
        reportButton
      }
    }
  }
  
  // MARK: 영상이름 수정 버튼
  private var videoTitleEditButton: some View {
    Button {
      showEditSheet()
    } label: {
      HStack {
        Image(systemName: "pencil")
          .tint(.labelStrong)
        Text(String(localized: "이름 수정"))
          .font(.headline1Medium)
      }
    }
  }
  // MARK: 영상이동 버튼
  private var videoEditButton: some View {
    Button {
      editAction()
    } label: {
      HStack {
        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
          .tint(sectionCount <= 1 ? Color.fillAssitive : Color.labelStrong)
        Text(String(localized: "다른 파트로 이동"))
          .font(.headline1Medium)
      }
    }
  }
  // MARK: 영삭삭제 버튼
  private var deleteButton: some View {
    Button(role: .destructive) {
      deleteAction()
    } label: {
      HStack {
        Image(systemName: "trash")
          .tint(.accentRedStrong)
        Text(String(localized: "영상 삭제"))
      }
    }
  }
  // MARK: 신고하기 버튼
  private var reportButton: some View {
    Button(role: .destructive) {
      showCreateReportSheet()
    } label: {
      HStack {
        Image(systemName: "light.beacon.max")
          .tint(.accentRedStrong)
        Text(String(localized: "신고하기"))
      }
    }
  }
}


#Preview {
  GridCell(
    size: 172,
    videoId: "",
    thumbnailURL: "https://picsum.photos/300",
    title: "2025-07-26 연습 영상",
    duration: 14.1414141414,
    uploadDate: Date(),
    currentUserId: "",
    videoUploaderId: "",
    editAction: {},
    deleteAction: {},
    showEditSheet: {},
    showCreateReportSheet: {},
    videoAction: {},
    sectionCount: 0
  )
}
