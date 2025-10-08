//
//  LoadingView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/8/25.
//

import SwiftUI

// FIXME: - 임시 로딩 뷰 (디자이너와 협의)
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.gray.opacity(0.75)
                .ignoresSafeArea()
            ProgressView()
        }
        .allowsHitTesting(true)
    }
}

#Preview {
    LoadingView()
}
