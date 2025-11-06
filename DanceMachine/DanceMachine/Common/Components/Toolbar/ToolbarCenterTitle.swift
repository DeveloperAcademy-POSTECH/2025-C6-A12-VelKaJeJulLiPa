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
        .font(.heading1Medium)
        .foregroundStyle(.labelStrong)
        .allowsHitTesting(false)
        .frame(maxWidth: .infinity)
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
