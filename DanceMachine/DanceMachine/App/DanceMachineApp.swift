//
//  DanceMachineApp.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore


class AppDelegate: NSObject, UIApplicationDelegate {
    // 전역 잠금 상태 (기본: 세로)
    static var orientationMask: UIInterfaceOrientationMask = .portrait

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("🔥 FirebaseApp configured")
        return true
    }
    
    // 전역으로 회전 방지 설정
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationMask
    }
}

@main
struct DanceMachineApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
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
                                .onOpenURL { url in
                                    inviteRouter.handleIncoming(url: url) // 초대 로직
                                }
                                // 유저 정보가 갱신되면 보류된 초대 재시도
                                .task(id: authManager.userInfo?.userId) {
                                    await MainActor.run {
                                        inviteRouter.processPendingIfPossible()
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

