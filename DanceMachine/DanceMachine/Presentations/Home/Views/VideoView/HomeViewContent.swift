//
//  HomeViewContent.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/22/25.
//

import SwiftUI

struct HomeViewContent: View {
  var body: some View {
    if UIDevice.current.userInterfaceIdiom == .pad {
      HomeSplitView()
    } else {
      HomeView()
    }
  }
}

#Preview {
  HomeViewContent()
}
