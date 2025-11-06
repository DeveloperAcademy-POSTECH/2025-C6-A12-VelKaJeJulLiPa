//
//  ThickDivider.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import SwiftUI

/// 두꺼운 구분선
struct ThickDivider: View { // FIXME: - Hi-fi 디자인 반영
  
  var body: some View {
    Rectangle()
      .foregroundStyle(Color.strokeNormal) // FIXME: - 컬러 수정
      .frame(height: 12) // FIXME: - 높이 수정
  }
}

#Preview {
  ThickDivider()
}
