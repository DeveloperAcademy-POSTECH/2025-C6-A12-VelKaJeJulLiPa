//
//  AuthNavigationRoutingView.swift
//  DanceMachine
//
//  Created by Paidion on 11/4/25.
//

import SwiftUI

struct AuthNavigationRoutingView: View {
  @EnvironmentObject var router: AuthRouter
  @State var destination: AuthRoute
  
    var body: some View {
      Group {
        switch destination {
        case .login:
          LoginView()
        }
      }
      .hideBackButton()
      .dismissKeyboardOnTap()
      .environmentObject(router)
    }
}
