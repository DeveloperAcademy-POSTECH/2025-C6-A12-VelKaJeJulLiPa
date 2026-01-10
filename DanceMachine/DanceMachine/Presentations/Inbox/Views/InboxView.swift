//
//  InboxView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI

struct InboxView: View {
  @EnvironmentObject private var router: MainRouter
  @StateObject private var viewModel = InboxViewModel()
  
  var body: some View {
    VStack(spacing: 0) {
      CustomNavigationBar(text: String(localized: "수신함"))
      // 메인 컨텐츠
      GeometryReader { g in
        ScrollView {
          if viewModel.isLoading && viewModel.inboxNotifications.isEmpty {
            loadingView
          } else if viewModel.inboxNotifications.isEmpty {
            emptyView(g: g)
          } else {
            content
          }
        }
        .background {
          Color.backgroundNormal.ignoresSafeArea()
        }
        .refreshable {
          await viewModel.refresh()
        }
        .overlay(alignment: .bottom) {
          if viewModel.isPaginationLoading {
            LoadingSpinner()
              .frame(width: 28, height: 28)
              .padding(.bottom, 19)
          }
        }
      }
    }
    .task {
      await viewModel.loadNotifications(reset: true)
    }
  }
  
  private var loadingView: some View {
    ForEach(0..<4, id: \.self) { _ in
      SkeletonInboxNotificationRow()
    }
  }
  
  private func emptyView(g: GeometryProxy) -> some View {
    VStack {
      Spacer()
      Image(systemName: "bell.slash.fill")
        .font(.system(size: 75))
        .foregroundStyle(.fillAssitive)
      Spacer().frame(height: 10)
      Text("받은 알림이 없습니다.")
        .font(.headline2Medium)
        .foregroundStyle(.labelAssitive)
      Spacer()
    }
    .frame(width: g.size.width, height: g.size.height)
    .position(
      x: g.size.width / 2,
      y: g.size.height / 2 - 40
    )
  }
  
  private var content: some View {
    LazyVStack(spacing: 0) {
      ForEach(viewModel.inboxNotifications, id: \.notificationId) { notification in
        InboxNotificationRow(notification: notification)
          .onTapGesture {
            guard let userId = FirebaseAuthManager.shared.userInfo?.userId else { return }
            Task {
              try await viewModel.markAsRead(
                userId: userId,
                notificationId: notification.notificationId
              )
              
              if NotificationManager.shared.unreadNotificationCount > 0 {
                NotificationManager.shared.unreadNotificationCount -= 1
              }
              
              router.push(
                to: .video(
                  .play(
                    videoId: notification.videoId,
                    videoTitle: notification.videoTitle,
                    videoURL: notification.videoURL,
                    teamspaceId: notification.teamspace.teamspaceId.uuidString
                  )
                )
              )
            }
          }
        // 가져온 알림 중에 마지막 알림일 떄, 다음 알림 목록 정보 로드 트리거
          .task(id: notification.notificationId) {
            if notification == viewModel.inboxNotifications.last {
              await viewModel.loadNotifications()
            }
          }
      }
    }
  }
}

#Preview {
  NavigationStack {
    InboxView()
  }
}
