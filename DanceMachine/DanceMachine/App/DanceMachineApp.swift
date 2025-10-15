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

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("🔥 FirebaseApp configured")
        
        return true
    }
}

@main
struct DanceMachineApp: App {
    @StateObject private var router: NavigationRouter = .init()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var authManager = FirebaseAuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch authManager.authenticationState {
                case .unauthenticated:
                    LoginView()
                        .transition(.opacity)
                    
                case .authenticated:
                    ZStack {
                        if !authManager.hasNameSet {
                            NameSettingView()
                        } else {
                            RootView()
                                .environmentObject(router)
                                .transition(.move(edge: .trailing))
                        }
                    }
                    .animation(.easeInOut, value: authManager.hasNameSet)
                }
            }
            .animation(.easeInOut, value: authManager.authenticationState)
            .onAppear {
                print("🚀 DanceMachineApp appeared")
                print("🚀 Authentication State is now \(authManager.authenticationState)")
            }
        }
    }
}
