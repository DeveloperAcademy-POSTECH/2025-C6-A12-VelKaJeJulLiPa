//
//  MyPageNavigationRow.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import SwiftUI

/// 마이페이지에서 정보를 보여줄 수 있고 네비게이션이 있는 행
struct MyPageNavigationRow: View {  // FIXME: - Hi-fi 스타일 적용
    let title: String
    var value: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.black) // FIXME: - 컬러 수정

                Spacer()
                
                if let value = value {
                    Text(value)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.black) // FIXME: - 컬러 수정
                        .padding(.trailing, 4)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.black) // FIXME: - 컬러 수정
            }
            .padding()
        }
    }
}

#Preview {
    MyPageNavigationRow(title: "TItle", value: "value", action: { print("Click") })
}
