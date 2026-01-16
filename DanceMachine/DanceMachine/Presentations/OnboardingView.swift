//
//  OnboardingView.swift
//  DanceMachine
//
//  Created by Paidion on 11/4/25.
//

import SwiftUI

struct OnboardingView: View {
  @EnvironmentObject private var router: AuthRouter
  
  @State private var isLaunch: Bool = true
  
  var body: some View {
    NavigationStack(path: $router.destination) {
      LoginView()
        .navigationDestination(for: AuthRoute.self) { destination in
          AuthNavigationRoutingView(destination: destination)
        }
    }
  }
}

struct LaunchScreenView: View {
  var body: some View {
    ZStack {
      Image(.splashBackground)
        .resizable()
        .scaledToFill()
        .ignoresSafeArea()
      Image(.splashIcon)
    }
  }
}


#Preview("로그인 온보딩") {
  OnboardingView()
    .environmentObject(AuthRouter())
}

#Preview("런치 스크린") {
  LaunchScreenView()
}


// OnBoardingView (Auth Router) 에서 스와이프해서 이전 화면으로 이동 방지
struct DisableSwipeBackGesture: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> UIViewController {
    let controller = UIViewController()
    DispatchQueue.main.async {
      controller.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    return controller
  }
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
