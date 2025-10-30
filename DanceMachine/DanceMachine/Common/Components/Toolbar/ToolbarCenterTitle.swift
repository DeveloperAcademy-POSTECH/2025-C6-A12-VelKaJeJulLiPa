//
//  ToolbarCenterTitle.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI

struct ToolbarCenterTitle: ToolbarContent {
    @Environment(\.colorScheme) var colorScheme
    
    let text: String
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(text)
                .font(Font.system(size: 18, weight: .semibold))
                .foregroundStyle(.black) // FIXME: 다크모드 배경색 명시
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
