//
//  DanceMachineApp.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import AuthenticationServices


@main
struct DanceMachineApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @Environment(\.scenePhase) private var scenePhase
  @StateObject private var authRouter = AuthRouter()
  @StateObject private var mainRouter = MainRouter()
  
  
  @StateObject private var authManager = FirebaseAuthManager.shared
  @StateObject private var inviteRouter = InviteRouter()
  
  init() {
    Task {
      await ListDataCacheManager.shared.cleanupOldCache()
      await VideoCacheManager.shared.cleanupOldCache()
    }
  }
    let tabBarAppearance = UITabBarAppearance()
    let itemAppearance = tabBarAppearance.stackedLayoutAppearance
    
    itemAppearance.normal.iconColor = UIColor(Color.labelStrong)
    itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.labelStrong)]
    itemAppearance.selected.iconColor = UIColor(Color.secondaryStrong)
    itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.secondaryStrong)]
    
    UITabBar.appearance().standardAppearance = tabBarAppearance
    UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
  }
  
  var body: some Scene {
    WindowGroup {
      Group {
        switch authManager.authenticationState {
        case .unauthenticated:
          OnboardingView()
            .environmentObject(authRouter)
            .transition(.opacity)
          
        case .authenticated:
          ZStack {
            if authManager.needsNameSetting {
              NameSettingView()
            } else {
              RootView()
                .environmentObject(mainRouter)
                .environmentObject(inviteRouter)
                .transition(.move(edge: .trailing))
              
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
                  if newPhase == .background {
                    Task {
                      await ListDataCacheManager.shared.cleanupOldCache()
                      await VideoCacheManager.shared.cleanupOldCache()
                    }
                  }
                }
              
              
              // 앱 종료된 상태에서 푸시 눌렀을 때,
              // currentTeamspace 세팅되고 변화 감지해서 화면 링크 처리
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
          let videoURL = query.first(where: { $0.name == "videoURL" })?.value,
          let teamspaceId = query.first(where: { $0.name == "teamspaceId" })?.value else {
      print("❌ Invalid video deeplink:", url.absoluteString)
      return
    }
    
    if case .video(.play) = mainRouter.destination.last {
      // 네비게이션 이동 없이 VideoView 자체 데이터 갱신 이벤트 보내기
      NotificationCenter.default.post(
        name: .refreshVideoView,
        object: nil,
        userInfo: [
          "videoId": videoId,
          "videoTitle": videoTitle,
          "videoURL": videoURL,
          "teamspaceId": teamspaceId
        ]
      )
    } else {
      // VideoView (영상 화면)으로 내비게이션
      mainRouter.push(to: .video(.play(videoId: videoId, videoTitle: videoTitle, videoURL: videoURL, teamspaceId: teamspaceId)))
    }
  }
}
