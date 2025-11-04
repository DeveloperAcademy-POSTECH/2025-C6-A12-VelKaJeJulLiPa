//
//  InboxView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI

// FIXME: Hi-fi 반영 및 리팩토링
struct InboxView: View {
  @EnvironmentObject private var router: MainRouter
  @StateObject private var viewModel = InboxViewModel()
  
  var body: some View {
    ZStack {
      Color.white.ignoresSafeArea() // FIXME: - 컬러 수정
      
      VStack {
        if viewModel.isLoading && viewModel.inboxNotifications.isEmpty {
          ProgressView()
            .frame(maxWidth: .infinity, alignment: .center)
        } else if viewModel.inboxNotifications.isEmpty {
          VStack(spacing: 10) {
            
            Image(systemName: "bell.slash.fill")
              .resizable()
              .foregroundStyle(.gray)                                        // FIXME: 컬러 수정
              .frame(width: 120, height: 110)                                // FIXME: 크기 수정
            Text("받은 알림이 없습니다.")
              .font(Font.system(size: 15))                         // FIXME: - 폰트 수정
              .foregroundStyle(Color.gray)                         // FIXME: - 컬러 수정
              .lineSpacing(6)                                      // FIXME: - 줄간격 수정
          }
        } else {
          List {
            ForEach(viewModel.inboxNotifications, id: \.notificationId) { notification in
              //TODO: 알림 목록 컴포넌트 분리
              //TODO: 알림 목록 읽음 상태 UI 반영
              HStack(spacing: 8) {
                //알림 유형(피드백 / 댓글)
                VStack(alignment: .leading) {
                  if notification.type == .feedback {
                    Image(systemName: "ellipsis.message")
                  } else {
                    Image(systemName: "arrowshape.turn.up.left")
                  }
                  Spacer()
                }
                .foregroundStyle(.purple)                                        // FIXME: 컬러 수정
                
                // 알림 전체 내용
                VStack(alignment: .leading, spacing: 12) {
                  // 비디오 제목 + 날짜
                  HStack(spacing: 0) {
                    Text(notification.videoTitle)
                      .font(Font.system(size: 14))                         // FIXME: - 폰트 수정
                      .foregroundStyle(Color.gray)                         // FIXME: - 컬러 수정
                      .multilineTextAlignment(.leading)
                      .lineSpacing(6)                                      // FIXME: - 줄간격 수정
                    
                    Spacer()
                    
                    Text(notification.date.listTimeLabel())
                      .font(Font.system(size: 14))                         // FIXME: - 폰트 수정
                      .foregroundStyle(Color.gray)                         // FIXME: - 컬러 수정
                      .multilineTextAlignment(.leading)
                      .lineSpacing(6)                                      // FIXME: - 줄간격 수정
                  }
                  
                  VStack(alignment: .leading, spacing: 8) {
                    // 알림 제목 (예시, 카단이 피드백을 남겼어요)
                    HStack(spacing: 0) {
                      Text(notification.senderName)
                        .font(Font.system(size: 18, weight: .semibold)) // FIXME: - 폰트 수정
                        .foregroundStyle(Color.gray)                    // FIXME: - 컬러 수정
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)                                 // FIXME: - 줄간격 수정
                      Text(koreanParticle(notification.senderName) + " ")
                        .font(Font.system(size: 18))                    // FIXME: - 폰트 수정
                        .foregroundStyle(Color.gray)                    // FIXME: - 컬러 수정
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)                                 // FIXME: - 줄간격 수정
                      Text(notification.type == .feedback ? "피드백을 남겼어요" : "답글을 남겼어요" )
                        .font(Font.system(size: 18))                    // FIXME: - 폰트 수정
                        .foregroundStyle(Color.gray)                    // FIXME: - 컬러 수정
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)                                 // FIXME: - 줄간격 수정
                    }
                    
                    // 알림 내용
                    Text(notification.content)
                      .font(Font.system(size: 16))                        // FIXME: - 폰트 수정
                      .foregroundStyle(Color.gray)                        // FIXME: - 컬러 수정
                      .multilineTextAlignment(.leading)
                      .lineSpacing(6)                                     // FIXME: - 줄간격 수정
                    
                  }
                }
              }
              // 목록 선택 영역 넓게 조정
              .contentShape(Rectangle())
              .listRowBackground(
                notification.isRead
                ? Color.white
                : Color.blue.opacity(0.1)
              )
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
          .refreshable {
            await viewModel.refresh()
          }
          .listStyle(.plain) // FIXME: - 알림 스타일 수정
          
          if viewModel.isLoading {  // FIXME: - 로딩 스타일 수정
            ProgressView()
              .frame(maxWidth: .infinity, alignment: .center)
              .padding()
          }
        }
      }
      .task {
        // 첫 진입 시 초기 데이터 로드
        await viewModel.loadNotifications(reset: true)
      }
    }
    .toolbar {
      ToolbarCenterTitle(text: "수신함")
    }
  }
}



#Preview {
  InboxView()
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
