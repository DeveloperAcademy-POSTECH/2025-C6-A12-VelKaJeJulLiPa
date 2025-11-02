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
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.gray)
        }
        .buttonStyle(.plain)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    XmarkButton() {}
        .frame(width: 19, height: 19)
}
