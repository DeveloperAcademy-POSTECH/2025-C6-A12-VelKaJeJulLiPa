//
//  ToastView.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/5/25.
//

import SwiftUI


struct ToastView: View {
  var text: String
  var icon: ToastIcon

  var body: some View {
    HStack {

      Image(systemName: icon.icon)
        .foregroundStyle(icon.iconColor)

      Text(text)
        .font(.headline2Medium)
        .foregroundStyle(.labelStrong)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 43, alignment: .leading)

    }
    .padding(.leading, 16)
    .background(
      RoundedRectangle(cornerRadius: 10)
        .fill(Color.fillAssitive)
    )
  }
}

#Preview {
  ToastView(text: "배고프다", icon: .check)
}
