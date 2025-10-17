//
//  ListCell.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/17/25.
//

import SwiftUI

struct ListCell: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(Font.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            Spacer()
            Image(systemName: "chevron.right") // FIXME: - 이미지 수정
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.gray)
        ) // FIXME: - 컬러 수정
    }
}

#Preview {
    ListCell(title: "2025 가을 축제")
        .padding(.horizontal, 16)
}
