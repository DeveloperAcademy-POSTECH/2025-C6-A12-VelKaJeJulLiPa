//
//  FeedbackListView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/25/25.
//

import SwiftUI
import Kingfisher


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
  
  var imageNamespace: Namespace.ID? = nil // 애니메이션 용
  
  var onImageTap: ((String) -> Void)? = nil

  @State private var showMenu: Bool = false
  @State private var isReplyPressed: Bool = false

  var body: some View {
    ZStack(alignment: .topTrailing) {
      VStack(alignment: .leading) {
        authorName
        Spacer().frame(height: 16)
        timeStamp
        Spacer().frame(height: 8)
        content
        Spacer().frame(height: 16)
        feedbackImageView
        HStack {
          if showBottomReplyButton {
            Button {
              onBottomReplyTap?()
            } label: {
              Text(String(localized: "답글달기"))
                .font(.caption1Medium)
                .foregroundStyle(.labelNormal)
            }
          }
          Spacer()
          replyButton
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 16)
    .background {
      VStack {
        Spacer()
        Rectangle()
          .frame(height: 0.5)
          .foregroundStyle(.strokeNormal)
      }
    }
    .contentShape(Rectangle())
//    .onTapGesture {
//      action()
//    }
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
      Text(authorUser?.name ?? String(localized: "알 수 없는 사용자"))
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
    .overlay(alignment: .trailing) {
      Menu {
        contextRow
      } label: {
        Image(systemName: "ellipsis")
          .font(.system(size: 14))
          .foregroundStyle(.labelNormal)
          .frame(width: 22, height: 22)
      }
      .frame(width: 44, height: 44)
      .contentShape(Rectangle())
      .offset(x: 11)  // 터치 영역 확장으로 인한 오른쪽 offset
      .tint(Color.accentRedStrong) // FIXME: 메뉴 버튼 스타일 수정
    }
  }
  
  private var timeStamp: some View {
    HStack {
      if let endTime = feedback.endTime {
        TimestampInput(
          text: "\(feedback.startTime?.formattedTime() ?? "00:00") ~ \(endTime.formattedTime())",
          timeSeek: { timeSeek() }
        )
      } else {
        TimestampInput(
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
      // 액션 비워둠 (simultaneousGesture에서 처리)
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
    .scaleEffect(isReplyPressed ? 1.3 : 1.0)
    .frame(maxWidth: .infinity, alignment: .trailing)
    .simultaneousGesture(
      TapGesture()
        .onEnded {
          // 햅틱 피드백
          let impact = UIImpactFeedbackGenerator(style: .light)
          impact.impactOccurred()

          // 애니메이션
          withAnimation(.easeInOut(duration: 0.1)) {
            isReplyPressed = true
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
              isReplyPressed = false
            }
          }

          showReplySheet()
        }
    )
  }
  
  private var contextRow: some View {
    VStack(alignment: .leading, spacing: 16) {
      if feedback.authorId == currentUserId {
        Button(role: .destructive) {
          onDelete()
        } label: {
          Label(String(localized: "삭제"), systemImage: "trash")
        }
      } else {
        Button(role: .destructive) {
          onReport()
        } label: {
          Label(String(localized: "신고하기"), systemImage: "light.beacon.max")
        }
      }
    }
  }
  
  // MARK: - 피드백 이미지
  private var feedbackImageView: some View {
    Group {
      if let urlString = feedback.imageURL,
         let url = URL(string: urlString) {
        // Namespace가 있는 경우와 없는 경우를 분기
        if let ns = imageNamespace {
          KFImage(url)
            .placeholder {
              ZStack {
                RoundedRectangle(cornerRadius: 8)
                  .fill(Color.backgroundElevated)
                  .frame(width: 100, height: 100)
                ProgressView() // FIXME: - 임시
              }
            }
            .retry(maxCount: 2, interval: .seconds(2))
            .cacheOriginalImage()
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .matchedGeometryEffect(id: urlString, in: ns)   // 🔥 hero 연결
            .highPriorityGesture(
              TapGesture()
                .onEnded {
                  onImageTap?(urlString)
                }
            )
//            .onTapGesture {
//              onImageTap?(urlString)
//            }
        } else {
          // 기존 동작(히어로 없이)도 유지
          KFImage(url)
            .placeholder {
              ZStack {
                RoundedRectangle(cornerRadius: 8)
                  .fill(Color.backgroundElevated)
                  .frame(width: 100, height: 100)
                ProgressView() // FIXME: - 임시
              }
            }
            .retry(maxCount: 2, interval: .seconds(2))
            .cacheOriginalImage()
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .highPriorityGesture(
              TapGesture()
                .onEnded {
                  onImageTap?(urlString)
                }
            )
//            .onTapGesture {
//              onImageTap?(urlString)
//            }
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
