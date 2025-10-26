//
//  MyPageRow.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import SwiftUI

/// 마이페이지에서 정보만 표시하는 행
struct MyPageInfoRow: View { // FIXME: - Hi-fi 스타일 적용
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    MyPageInfoRow(title: "TItle", value: "value")
}
