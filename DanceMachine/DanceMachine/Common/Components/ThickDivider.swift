//
//  ThickDivider.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import SwiftUI

/// 두꺼운 구분선
struct ThickDivider: View { // FIXME: - Hi-fi 디자인 반영
    
    @Environment(\.colorScheme) var colorScheme
    
    var color: Color { // FIXME: - 컬러 수정
        colorScheme == .light ? .gray.opacity(0.2) : .white.opacity(0.2)
    }
    
    var body: some View {
        Rectangle()
            .foregroundStyle(color)
            .frame(height: 12) // FIXME: - 높이 수정
    }
}

#Preview {
    ThickDivider()
}
