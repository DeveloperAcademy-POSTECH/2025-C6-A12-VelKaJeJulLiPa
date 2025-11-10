//
//  MyPageView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI
import UserNotifications

struct MyPageView: View {
  
  @EnvironmentObject private var router: MainRouter
  
  @State private var viewModel = MyPageViewModel()
  
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      
      VStack(spacing: 0) {
        HStack {
          Text("마이페이지")
            .font(.title2SemiBold)
            .foregroundStyle(.labelStrong)
          Spacer()
        }
        .padding()
        
        VStack(spacing: 0) {
          MyPageInfoRow(title: "ID", value: viewModel.myId, isDividerPresented: true)
          MyPageNavigationRow(title: "나의 이름", value: viewModel.myName) {
            router.push(to: .mypage(.editName))
          }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        
        
        ThickDivider()
        
        
        VStack(spacing: 0) {
          MyPageNavigationRow(title: "개인정보처리방침", isDividerPresented: true) {
            router.push(to: .mypage(.privacyPolicy))
          }
          MyPageNavigationRow(title: "서비스 이용약관", isDividerPresented: true) {
            router.push(to: .mypage(.termsOfUse))
          }
          MyPageNavigationRow(title: "알림 수신") {
            viewModel.openAppSettings()
          }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        
        
        ThickDivider()
        
        
        VStack(spacing: 0) {
          MyPageNavigationRow(title: "계정 설정", isDividerPresented: true) {
            router.push(to: .mypage(.accountSetting))
          }
          MyPageInfoRow(title: "앱 버전", value: viewModel.appVersion, isDividerPresented: true)
          MyPageNavigationRow(title: "DirAct를 만든 사람들") {
            router.push(to: .mypage(.appMaker))
          }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        
        
        Spacer()
      }
    }
  }
}


#Preview {
  MyPageView()
    .environmentObject(MyPageViewModel())
}
