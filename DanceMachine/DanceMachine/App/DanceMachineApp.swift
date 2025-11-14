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
import SwiftData


@main
struct DanceMachineApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @Environment(\.scenePhase) private var scenePhase
  @StateObject private var authRouter = AuthRouter()
  @StateObject private var mainRouter = MainRouter()
  
  
  @StateObject private var authManager = FirebaseAuthManager.shared
  @StateObject private var inviteRouter = InviteRouter()
  
  // 여기서는 선언만
  let container: ModelContainer
  let cacheStore: CacheStore
  
  init() {
    // init에서 한 번만 생성하고 공유
    let container = try! ModelContainer(
      for: TeamspaceCache.self
      // , TeamspaceEntity.self ...
    )
    self.container = container
    self.cacheStore = CacheStore(container: container)
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
                .modelContainer(container)
                .environment(\.cacheStore, cacheStore)
                    
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
    mainRouter.push(to: .video(.play(videoId: videoId, videoTitle: videoTitle, videoURL: videoURL)))
    
    print("🎬 Navigate to VideoView:", videoTitle)
  }
}
