//  ActionButton.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/15/25.
//

import SwiftUI

/// 액션 버튼 컴포넌트 입니다.
/// - Parameters:
///     - title: 버튼 타이틀
///     - color: 버튼의 색
///     - height: 버튼의 높이
///     - action: 버튼의 액션
struct ActionButton: View {
    let title: String
    let color: Color
    let height: CGFloat
    var isEnabled: Bool = true
    let action: () -> Void
    
    init(
        title: String,
        color: Color,
        height: CGFloat,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.color = color
        self.height = height
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            RoundedRectangle(cornerRadius: 5)
                .fill(color)
                .overlay {
                    Text(title)
                        .font(Font.system(size: 16, weight: .medium)) // FIXME: - 폰트 수정
                        .foregroundStyle(Color.white) // FIXME: - 컬러 수정
                }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .disabled(!isEnabled)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack {
        ActionButton(
            title: "메인 액션",
            color: Color.blue,
            height: 47
        ) {
            
        }
    }
    .padding(.horizontal, 16)
}
