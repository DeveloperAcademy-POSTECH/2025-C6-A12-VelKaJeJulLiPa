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
      
      VStack {
        if viewModel.isLoading && viewModel.inboxNotifications.isEmpty {
          ProgressView()
            .frame(maxWidth: .infinity, alignment: .center)
        } else if viewModel.inboxNotifications.isEmpty {
          VStack {
            Spacer()
            Image(systemName: "bell.slash.fill")
              .resizable()
              .foregroundStyle(.fillAssitive)
              .frame(width: 138, height: 110)
            Spacer().frame(height: 10)
            Text("받은 알림이 없습니다.")
              .font(.headline2Medium)
              .foregroundStyle(.labelAssitive)
            Spacer()
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
                      
                      router.push(
                        to: .video(
                          .play(
                            videoId: notification.videoId,
                            videoTitle: notification.videoTitle,
                            videoURL: notification.videoURL
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
          
          if viewModel.isLoading {  // FIXME: - 로딩 스타일 수정
            ProgressView()
              .tint(.labelStrong)
              .frame(maxWidth: .infinity, alignment: .center)
              .padding(.bottom, 16)
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



/// 올바른 주격 조사를 반환하는 메서드입니다.
/// "가" 혹은 "이"를 반환합니다.
func koreanParticle(_ input: String) -> String {
  
  guard let text = input.last else { return input }
  
  let val = UnicodeScalar(String(text))?.value
  guard let value = val else { return input }
  // 종성 인덱스 계산
  let index = (value - 0xac00) % 28
  // 조사 판별 후 리턴
  if index == 0 {
    return "가" // 를
  } else {
    return "이" // 을
  }
}
