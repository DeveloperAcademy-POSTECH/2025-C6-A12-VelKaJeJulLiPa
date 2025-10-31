//
//  ToolbarCenterTitle.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI

struct ToolbarCenterTitle: ToolbarContent {
    
    let text: String
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(text)
                .font(Font.system(size: 18, weight: .semibold)) // FIXME: - 폰트 수정
                .foregroundStyle(Color.black) // FIXME: - 컬러 수정
                .allowsHitTesting(false)
        }
    }
}

#Preview {
    NavigationStack {
        Text("Preview")
            .toolbar {
                ToolbarCenterTitle(text: "안녕하세요")
            }
    }
}
