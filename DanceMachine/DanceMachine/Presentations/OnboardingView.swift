//
//  OnboardingView.swift
//  DanceMachine
//
//  Created by Paidion on 11/4/25.
//

import SwiftUI

struct OnboardingView: View {
  @EnvironmentObject private var router: AuthRouter
  
  var body: some View {
    NavigationStack(path: $router.destination) {
      LoginView()
        .navigationDestination(for: AuthRoute.self) { destination in
          AuthNavigationRoutingView(destination: destination)
        }
    }
  }
}


#Preview {
  OnboardingView()
    .environmentObject(AuthRouter())
}
