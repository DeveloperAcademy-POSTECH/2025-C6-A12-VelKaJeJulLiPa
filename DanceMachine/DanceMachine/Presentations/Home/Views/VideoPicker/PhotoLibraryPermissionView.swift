//
//  PhotoLibraryPermissionView.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/1/25.
//

import SwiftUI

struct PhotoLibraryPermissionView: View {
  let onOpenSettigns: () -> Void
  let action: () -> Void
  
  var body: some View {
    ZStack {
      Color.black.opacity(0.7)
        .ignoresSafeArea()
        .onTapGesture {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            action()
          }
        }
      VStack(spacing: 24) {
        textView
        button
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 20)
      .background {
        RoundedRectangle(cornerRadius: 38)
          .fill(.backgroundElevated)
      }
      .padding(.horizontal, 44)
    }
  }
  
  private var textView: some View {
    VStack(spacing: 16) {
      Text("갤러리 접근 권한 요청")
        .font(.heading1SemiBold)
        .foregroundStyle(.labelStrong)
        .multilineTextAlignment(.center)
      
      Text("회원님의 라이브러리 영상 파일을\n불러오기 위한 접근 권한이 필요합니다.")
        .font(.headline2Medium)
        .foregroundStyle(.labelStrong)
        .multilineTextAlignment(.center)
        .lineSpacing(2)
    }
  }
  
  private var button: some View {
    Button {
      onOpenSettigns()
    } label: {
      Text("접근 허용")
        .font(.headline2Medium)
        .foregroundStyle(.labelStrong)
        .frame(maxWidth: .infinity)
        .frame(height: 45)
        .background(.primitiveStrong)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    .padding(.horizontal, 16)
  }
}

#Preview {
  PhotoLibraryPermissionView(onOpenSettigns: {}, action: {})
}
