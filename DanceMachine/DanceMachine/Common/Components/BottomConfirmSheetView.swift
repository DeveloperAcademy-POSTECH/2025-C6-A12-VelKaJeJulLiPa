//
//  BottomConfirmSheetView.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/16/25.
//

import SwiftUI

/// 바텀 시트 뷰
struct BottomConfirmSheetView: View {
    let titleText: String
    let primaryText: String
    let action: () -> Void
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            BottomConfirmSheet(
                titleText: titleText,
                primaryText: primaryText
            ) { action() }
            .padding(.horizontal, 16)
            .padding(.vertical, 33)
            .presentationDetents([.fraction(0.4)])
            .presentationCornerRadius(16)
        }
    }
}

#Preview {
    BottomConfirmSheetView(
        titleText: "조카단\n팀스페이스를 나가시겠어요?",
        primaryText: "나가기") {
            
        }
}
