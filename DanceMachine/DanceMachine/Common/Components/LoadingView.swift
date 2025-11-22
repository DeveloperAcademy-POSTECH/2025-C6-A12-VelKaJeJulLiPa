//
//  LoadingView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/8/25.
//

import SwiftUI

struct LoadingView: View {
  var body: some View {
    ZStack {
      Color.materialDimmer.ignoresSafeArea()
      VStack {
        LoadingSpinner()
          .frame(width: 28, height: 28)
      }
    }
    .zIndex(999)
    .allowsHitTesting(true)
  }
}

#Preview {
  LoadingView()
}

