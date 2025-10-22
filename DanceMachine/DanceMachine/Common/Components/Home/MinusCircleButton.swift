//
//  MinusCircleButton.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/16/25.
//

import SwiftUI

struct MinusCircleButton: View {
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(.minusCircle) // FIXME: - 이미지 수정 (임시)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24) // FIXME: - 크기 수정
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .frame(minWidth: 24, minHeight: 24) // FIXME: - 크기 수정
    }
}

#Preview {
    MinusCircleButton() {}
}
