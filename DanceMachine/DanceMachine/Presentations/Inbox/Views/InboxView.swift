//
//  InboxView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI

struct InboxView: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            Text("Coming Soon")
                .font(Font.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.black)
        }
    }
}

#Preview {
    InboxView()
}
