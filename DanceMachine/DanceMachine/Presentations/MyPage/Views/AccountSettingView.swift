//
//  AccountSettingView.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import SwiftUI

struct AccountSettingView: View {
  
  @EnvironmentObject private var router: MainRouter
  
  @State private var viewModel = AccountSettingViewModel()
  
  @State private var isSignOutAlertPresented: Bool = false
  @State private var isDeleteUserAlertPresented: Bool = false
  
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      
      VStack(spacing: 0) {
        MyPageInfoRow(title: "ID", value: viewModel.myId, isDividerPresented: true)
          .padding(.vertical, 8)
          .padding(.horizontal, 16)
        
        Spacer()
        
        ActionButton(
          title: "로그아웃",
          color: .secondaryStrong,
          height: 47,
          action: { isSignOutAlertPresented = true }
        )
        .padding()
        
        Button {
          isDeleteUserAlertPresented = true
        } label: {
          Text("회원탈퇴")
            .foregroundStyle(.accentRedStrong)
        }
      }
    }
    .toolbar {
      ToolbarLeadingBackButton(icon: .chevron)
      ToolbarCenterTitle(text: "계정 설정")
    }
    .alert(
      "로그아웃",
      isPresented: $isSignOutAlertPresented
    ) {
      Button("취소", role: .cancel) {}
      Button("로그아웃", role: .destructive) {
        Task {
          try await viewModel.signOut()
          router.destination.removeAll()
        }
      }
    } message: {
      Text("정말 로그아웃하시겠어요?")
    }
    .alert(
      "회원탈퇴",
      isPresented: $isDeleteUserAlertPresented
    ) {
      Button("취소", role: .cancel) {}
      Button("탈퇴", role: .destructive) {
        Task {
          try await viewModel.deleteUserAccount()
          router.destination.removeAll()
        }
      }
    } message: {
      Text("회원 정보가 삭제되고 되돌릴 수 없습니다.")
    }
  }
}


#Preview {
  NavigationStack {
    AccountSettingView()
      .environmentObject(MainRouter())
  }
}
