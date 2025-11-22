//
//  VideoDownloadError.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/19/25.
//

import SwiftUI

struct VideoDownloadError: View {
  @State private var isRotating: Bool = false
  let action: () -> Void
  
  var body: some View {
    VStack(spacing: 13) {
      image
      content
    }
  }
  
  private var image: some View {
    VStack(spacing: 4) {
      Image(systemName: "arrow.clockwise")
        .font(.system(size: 30, weight: .semibold))
        .foregroundStyle(.accentRedNormal)
        .symbolEffect(
          .rotate,
          options: .repeat(1).speed(1.5),
          isActive: isRotating
        )
        .onTapGesture {
          isRotating.toggle()
          DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            action()
          }
        }
      Text("재시도")
        .font(.headline2Medium)
        .foregroundStyle(.labelAssitive)
    }
  }
  
  private var content: some View {
    HStack(spacing: 3) {
      Image(systemName: "exclamationmark.circle.fill")
        .foregroundStyle(.accentRedNormal)
        .font(.footnoteMedium)
      Text("동영상 다운로드를 실패했습니다.")
        .font(.footnoteMedium)
        .foregroundStyle(.accentRedNormal)
    }
  }
}

#Preview {
  VideoDownloadError(action: {})
}
