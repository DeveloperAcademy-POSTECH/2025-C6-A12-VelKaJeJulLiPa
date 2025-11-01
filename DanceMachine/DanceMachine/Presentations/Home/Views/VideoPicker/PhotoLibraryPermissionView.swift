//
//  PhotoLibraryPermissionView.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/1/25.
//

import SwiftUI

struct PhotoLibraryPermissionView: View {
  let onOpenSettigns: () -> Void
  
  var body: some View {
    VStack(spacing: 24) {
      textView
      button
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.white)
  }
  
  private var textView: some View {
    VStack {
      Text("사진에 접근할 수 있도록 허가해 주세요ㅎㅎ")
        .font(.system(size: 20))
        .foregroundStyle(.black)
        .multilineTextAlignment(.center)
      
      Text("엑세스를 허용하면 DirAct에서 회원님의\n라이브러리에 있는 동영상을 공유할 수 있어요 ㅇㅈ?")
        .font(.system(size: 14))
        .foregroundStyle(.black)
        .multilineTextAlignment(.center)
        .lineSpacing(4)
    }
    .padding(.horizontal, 32)
  }
  
  private var button: some View {
    Button {
      onOpenSettigns()
    } label: {
      Text("라이브러리 엑세스 허용")
        .font(.system(size: 16))
        .foregroundStyle(.red)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.blue)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding(.horizontal, 32)
    .padding(.top, 16)
  }
}

#Preview {
  PhotoLibraryPermissionView(onOpenSettigns: {})
}
