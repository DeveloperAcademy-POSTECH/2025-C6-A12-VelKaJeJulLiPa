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
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      
      VStack(spacing: 0) {
        if viewModel.isLoading && viewModel.inboxNotifications.isEmpty {
          LoadingSpinner()
            .frame(maxWidth: 28, maxHeight: 28, alignment: .center)
        } else if viewModel.inboxNotifications.isEmpty {
          GeometryReader { geometry in
            ScrollView {
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
              .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .presentationDragIndicator(.hidden)
            .refreshable {
              await viewModel.refresh()
            }
          }
        } else {
          ScrollView {
            LazyVStack(spacing: 0) {
              ForEach(viewModel.inboxNotifications, id: \.notificationId) { notification in
                InboxNotificationRow(notification: notification)
                  .onTapGesture {
                    Task {
                      try await viewModel.markAsRead(
                        userId: FirebaseAuthManager.shared.userInfo?.userId ?? "",
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
          .refreshable {
            await viewModel.refresh()
          }
          
          if !viewModel.isRefreshing && viewModel.isLoading {
            LoadingSpinner()
              .frame(maxWidth: 28, maxHeight: 28, alignment: .center)
              .padding(.top, 7)
              .padding(.bottom, 19)
          }
        }
      }
      .task {
        await viewModel.loadNotifications(reset: true)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarCenterTitle(text: "수신함")
    }
  }
}
