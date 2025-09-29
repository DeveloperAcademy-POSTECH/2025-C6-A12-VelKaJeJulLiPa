//
//  ToolbarLeadingBackButton.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//


import SwiftUI

/// 뒤로가기 버튼입니다.
struct ToolbarLeadingBackButton: ToolbarContent {
    @Environment(\.dismiss) private var dismiss
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Color.gray)
                    .frame(width: 24, height: 24)
            }
            .padding(.leading, -8)
        }
    }
}

#Preview {
    NavigationStack {
        Text("Preview")
            .toolbar {
                ToolbarLeadingBackButton()
            }
    }
}
