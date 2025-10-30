//
//  DanceMachineApp.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore


@main
struct DanceMachineApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @Environment(\.scenePhase) private var scenePhase
  @StateObject private var router: NavigationRouter = .init()
  @StateObject private var authManager = FirebaseAuthManager.shared
  @StateObject private var inviteRouter = InviteRouter()
  
  
  var body: some Scene {
    WindowGroup {
      Group {
        switch authManager.authenticationState {
        case .unauthenticated:
          LoginView()
            .transition(.opacity)
          
        case .authenticated:
          ZStack {
            if authManager.needsNameSetting {
              NameSettingView()
            } else {
              RootView()
                .environmentObject(router)
                .transition(.move(edge: .trailing))
                .environmentObject(inviteRouter)
              
              // URL Scheme 또는 Universal Link로 들어온 경우 처리
                .onOpenURL { url in
                  handleIncomingURL(url)
                }
              
              // 포그라운드 상태에서 푸시 눌렀을 때 링크 처리
                .onReceive(NotificationCenter.default.publisher(for: .didReceiveDeeplink)) { note in
                  if let url = note.object as? URL {
                    handleIncomingURL(url)
                  }
                }
              
              // 백그라운드 상태에서 푸시 눌렀을 때 링크 처리 + 알림 읽음 처리
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active && authManager.currentTeamspace != nil {
                        Task {
                            if let pendingDeeplinkURL = AppDelegate.pendingDeeplinkURL {
                                handleIncomingURL(pendingDeeplinkURL)
                                AppDelegate.pendingDeeplinkURL = nil
                            }

                            if let pendingNotificationId = AppDelegate.pendingNotificationId,
                               let userId = FirebaseAuthManager.shared.userInfo?.userId {
                                do {
                                    try await NotificationManager.shared.markNotificationAsRead(
                                        userId: userId,
                                        notificationId: pendingNotificationId
                                    )
                                    AppDelegate.pendingNotificationId = nil
                                    print("✅ 보류된 알림 읽음 처리 완료")
                                } catch {
                                    print("❌ 알림 읽음 처리 실패:", error.localizedDescription)
                                }
                            }
                        }
                    }
                }

              
              // 앱 종료된 상태에서 푸시 눌렀을 때,
              // currentTeamspace 세팅되고 변화 감지해서 화면 링크 처리
              // TODO: 팀스페이스가 여러 개일 때, 푸시 알림 처리 논의 필요
                .onChange(of: authManager.currentTeamspace != nil) { oldState, newState in
                  if newState {
                    Task {
                      if let pendingDeeplinkURL = AppDelegate.pendingDeeplinkURL {
                        handleIncomingURL(pendingDeeplinkURL)
                        AppDelegate.pendingDeeplinkURL = nil
                      }
                      
                      if let pendingNotificationId = AppDelegate.pendingNotificationId,
                         let userId = FirebaseAuthManager.shared.userInfo?.userId {
                        do {
                          try await NotificationManager.shared.markNotificationAsRead(
                            userId: userId,
                            notificationId: pendingNotificationId
                          )
                          AppDelegate.pendingNotificationId = nil
                          print("✅ 보류된 알림 읽음 처리 완료")
                        } catch {
                          print("❌ 알림 읽음 처리 실패:", error.localizedDescription)
                        }
                      }
                    }
                  }
                }
              
              
              //FIXME: 아래 코드 커밋하지 않기!
              Button("피드백 생성") {
                Task {
                  do {
                    let fb = Feedback(
                      feedbackId: UUID(),
                      videoId: "DF1B4DAD-2081-4DFF-98CD-B8F3B1A7CC18",
                      authorId: "HqU0UNmrS5UBhxKZjhz4wqku4XB3",
                      content: "파이디온 푸시 알림 테스트용입니다!",
                      taggedUserIds: ["pt53sG8cbrMuwPE4NgKAbTkOoEQ2"],
                      teamspaceId: "4924D4B8-EB08-4AB8-B89D-CD4E4A4BE4E9")
                    
                    try await FirestoreManager.shared.create(fb)
                  }
                }
              }
              
              
              
            }
          }
          .animation(.easeInOut, value: authManager.needsNameSetting)
        }
      }
      .animation(.easeInOut, value: authManager.authenticationState)
    }
  }
}


extension DanceMachineApp {
  private func handleIncomingURL(_ url: URL) {
    // 초대 링크 (Universal link 또는 custom scheme)
    if url.host == "invite" || url.path == "/invite" {
      inviteRouter.handleIncoming(url: url)
      return
    }
    
    // 비디오 관련 링크 (푸시 알림)
    if url.host == "video" {
      handleDeeplink(url)
      return
    }
    
    print("⚠️ Unknown deeplink received:", url.absoluteString)
  }
  
  private func handleDeeplink(_ url: URL) {
    guard url.pathComponents.contains("view"),
          let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
          let videoId = query.first(where: { $0.name == "videoId" })?.value,
          let videoTitle = query.first(where: { $0.name == "videoTitle" })?.value,
          let videoURL = query.first(where: { $0.name == "videoURL" })?.value else {
      print("❌ Invalid video deeplink:", url.absoluteString)
      return
    }
    
    // videoView (영상 화면)으로 이동
    router.push(to: .video(.play(videoId: videoId, videoTitle: videoTitle, videoURL: videoURL)))
    
    print("🎬 Navigate to VideoView:", videoTitle)
  }
}
