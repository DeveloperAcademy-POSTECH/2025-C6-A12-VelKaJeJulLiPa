//
//  FeedbackListView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/25/25.
//

import SwiftUI

struct FeedbackCard: View {
  let feedback: Feedback
  let authorUser: User?
  let taggedUsers: [User]
  let replyCount: Int
  let action: () -> Void
  let showReplySheet: () -> Void

  let currentTime: Double
  let startTime: Double?
  let timeSeek: () -> Void

  let currentUserId: String
  let onDelete: () -> Void
  let onReport: () -> Void

  var showBottomReplyButton: Bool = false
  var onBottomReplyTap: (() -> Void)? = nil
  
  var onImageTap: ((String) -> Void)? = nil

  @State private var showMenu: Bool = false
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      VStack(alignment: .leading, spacing: 8) {
        authorName
        Spacer().frame(height: 2)
        timeStamp
        Spacer().frame(height: 2)
        content
        feedbackImageView
        HStack {
          if showBottomReplyButton {
            Button {
              onBottomReplyTap?()
            } label: {
              Text("답글달기")
                .font(.caption1Medium)
                .foregroundStyle(.labelNormal)
            }
          }
          Spacer()
          replyButton
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 16)

      Menu {
        contextRow
      } label: {
        Image(systemName: "ellipsis")
          .font(.system(size: 14))
          .foregroundStyle(.labelNormal)
      }
      .frame(width: 22, height: 22)
      .contentShape(Rectangle())
      .padding(.horizontal, 16)
      .padding(.top, 8)
      .tint(Color.accentRedStrong) // FIXME: 메뉴 버튼 스타일 수정
    }
    .background {
      VStack {
        Spacer()
        Rectangle()
          .frame(height: 0.5)
          .foregroundStyle(.labelAssitive)
      }
    }
    .contentShape(Rectangle())
    .onTapGesture {
      action()
    }
    .onLongPressGesture(perform: {
      action()
    })
    .contextMenu {
      contextRow
    }
    .sensoryFeedback(.success, trigger: showMenu)
  }
  
  private var authorName: some View {
    HStack {
      Text(authorUser?.name ?? "알 수 없는 사용자")
        .font(.footnoteSemiBold)
        .foregroundStyle(.labelNormal)
      Text("·")
        .font(.footnoteSemiBold)
        .foregroundStyle(.labelAssitive)
      if feedback.createdAt != nil {
        Text(
          feedback.createdAt?.listTimeLabel() ?? ""
        )
        .font(.footnoteSemiBold)
        .foregroundStyle(.labelAssitive)
      }
      Spacer()
    }
  }
  
  private var timeStamp: some View {
    HStack {
      if let endTime = feedback.endTime {
        TimestampButton(
          text: "\(feedback.startTime?.formattedTime() ?? "00:00") ~ \(endTime.formattedTime())",
          timeSeek: { timeSeek() }
        )
      } else {
        TimestampButton(
          text: "\(feedback.startTime?.formattedTime() ?? "00:00")",
          timeSeek: { timeSeek() }
        )
      }
      
      if !taggedUsers.isEmpty {
        Menu {
          ForEach(taggedUsers, id: \.userId) { user in
            Text(user.name)
          }
        } label: {
          HStack {
            ForEach(taggedUsers.prefix(3), id: \.userId) { user in
              Text("@\(user.name)")
                .font(.headline2Medium)
                .foregroundStyle(.accentBlueStrong)
            }
            if taggedUsers.count > 4 {
              moreButton
            }
          }
          .lineLimit(1)
          .truncationMode(.tail)
        }
      }
//      Spacer()
    }
  }
  
  private var moreButton: some View {
    VStack {
      Text("+\(taggedUsers.count - 3)")
        .font(.caption1Medium)
        .foregroundStyle(.labelStrong)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
    .background {
      RoundedRectangle(cornerRadius: 10)
        .fill(.primitiveStrong)
    }
  }
  
  private var content: some View {
    Text(feedback.content)
      .font(.body1Medium)
      .foregroundStyle(.labelStrong)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  private var replyButton: some View {
    Button {
      showReplySheet()
    } label: {
      HStack(spacing: 4) {
        Image(systemName: "message")
          .font(.system(size: 12))
          .foregroundStyle(.primitiveAssitive)
          .scaleEffect(x: -1, y: 1)
        Text("\(replyCount)")
          .font(.system(size: 12))
          .foregroundStyle(.primitiveAssitive)
      }
    }
    .buttonStyle(.plain)
    .frame(maxWidth: .infinity, alignment: .trailing)
  }
  
  private var contextRow: some View {
    VStack(alignment: .leading, spacing: 16) {
      if feedback.authorId == currentUserId {
        Button(role: .destructive) {
          onDelete()
        } label: {
          Label("삭제", systemImage: "trash")
        }
      } else {
        Button(role: .destructive) {
          onReport()
        } label: {
          Label("신고하기", systemImage: "light.beacon.max")
        }
      }
    }
  }
  
  // MARK: - 피드백 이미지
  private var feedbackImageView: some View {
    Group {
      if let urlString = feedback.imageURL,
         let url = URL(string: urlString) {
        AsyncImage(url: url) { phase in
          switch phase {
          case .empty:
            ZStack {
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.backgroundElevated)
                .frame(width: 100, height: 100)
              ProgressView()
            }
            
          case .success(let image):
            image
              .resizable()
              .scaledToFill()
              .frame(width: 100, height: 100)
              .clipShape(RoundedRectangle(cornerRadius: 8))
              .onTapGesture {
                onImageTap?(urlString)
              }
          case .failure(_):
            ZStack {
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.backgroundElevated)
                .frame(width: 100, height: 100)
              Image(systemName: "photo")
                .font(.system(size: 20))
                .foregroundStyle(.labelAssitive)
            }
            
          @unknown default:
            EmptyView()
          }
        }
      }
    }
  }
}

#Preview {
  FeedbackCard(
    feedback: Feedback(
      feedbackId: UUID(),
      videoId: "",
      authorId: "dddd",
      content: "야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아,야이 놈아,야이 놈아,야이 놈아,야이 놈아,야이 놈아",
      startTime: 1.44141414,
      endTime: 1.55555,
      createdAt: Date().addingTimeInterval(-60 * 0.5),
      teamspaceId: "",
    ),
    authorUser: User(
      userId: "1",
      email: "",
      name: "조재훈",
      loginType: LoginType.apple,
      fcmToken: "",
      termsAgreed: true,
      privacyAgreed: true,
    ),
    taggedUsers: [
      User(
        userId: "dd1",
        email: "",
        name: "조조조재훈",
        loginType: LoginType.apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      ),
      User(
        userId: "ddd2",
        email: "",
        name: "조조조훈",
        loginType: LoginType.apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      ),
      User(
        userId: "ddd3",
        email: "",
        name: "조재재재재재훈",
        loginType: LoginType.apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      ),
      User(
        userId: "d4",
        email: "",
        name: "조재훈",
        loginType: LoginType.apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      ),
      User(
        userId: "d5",
        email: "",
        name: "조재훈",
        loginType: LoginType.apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      )
    ],
    replyCount: 20,
    action: {
    },
    showReplySheet: {},
    currentTime: 30.0,
    startTime: 50.0,
    timeSeek: {},
    currentUserId: "",
    onDelete: {},
    onReport: {}
  )
}
