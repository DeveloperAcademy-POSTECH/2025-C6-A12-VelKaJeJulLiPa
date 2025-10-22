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

