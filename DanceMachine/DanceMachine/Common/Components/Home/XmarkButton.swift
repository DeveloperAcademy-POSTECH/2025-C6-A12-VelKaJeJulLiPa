//
//  XmarkButton.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/17/25.
//

import SwiftUI

/// SFsymbols 이미지를 사용하는 Xmark Button입니다.
struct XmarkButton: View {
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "xmark") // FIXME: - 이미지 교체
                .foregroundStyle(Color.white)
                .background(
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 19, height: 19)
                )
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    XmarkButton() {}
        .frame(width: 19, height: 19)
}
