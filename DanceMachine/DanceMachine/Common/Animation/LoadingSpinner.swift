//
//  LoadingSpinner.swift
//  DanceMachine
//
//  Created by Paidion on 11/10/25.
//

import SwiftUI
import Lottie

struct LoadingSpinner: View {
    var body: some View {
      LottieView(animation: .named("SpinnerPurple"))
        .playing(loopMode: .loop)
    }
}

#Preview {
    LoadingSpinner()
}
