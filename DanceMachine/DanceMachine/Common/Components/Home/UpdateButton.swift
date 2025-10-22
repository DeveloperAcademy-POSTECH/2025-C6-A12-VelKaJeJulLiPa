//
//  UpdateButton.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/16/25.
//

import SwiftUI

struct UpdateButton: View {
    let title: String
    let titleColor: Color
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(Font.system(size: 16, weight: .semibold)) // FIXME: - 폰트 수정
                .foregroundStyle(titleColor)
        }
    }
}

#Preview {
    UpdateButton(
        title: "수정하기",
        titleColor: Color.gray
    ) {
        
    }
}
