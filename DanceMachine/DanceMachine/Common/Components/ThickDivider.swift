//
//  ThickDivider.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import SwiftUI

/// 두꺼운 구분선
struct ThickDivider: View {
  
  var body: some View {
    Rectangle()
      .foregroundStyle(.strokeNormal)
      .frame(height: 12)
  }
}

#Preview {
  ThickDivider()
}
