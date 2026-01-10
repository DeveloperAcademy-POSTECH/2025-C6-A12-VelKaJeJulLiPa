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
  
  @State private var showContactView: Bool = false
  @State private var showContactSucessToast: Bool = false
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      
      VStack(spacing: 0) {
        CustomNavigationBar(text: String(localized: "마이페이지"))
        
        VStack(spacing: 0) {
          MyPageInfoRow(title: "ID", value: viewModel.myId, isDividerPresented: true)
          MyPageNavigationRow(title: String(localized: "나의 이름"), value: viewModel.myName) {
            router.push(to: .mypage(.editName))
          }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        
        
        ThickDivider()
        
        
        VStack(spacing: 0) {
          MyPageNavigationRow(title: String(localized: "개인정보처리방침"), isDividerPresented: true) {
            router.push(to: .mypage(.privacyPolicy))
          }
          MyPageNavigationRow(title: String(localized: "서비스 이용약관"), isDividerPresented: true) {
            router.push(to: .mypage(.termsOfUse))
          }
          MyPageNavigationRow(title: String(localized: "알림 수신")) {
            viewModel.openAppSettings()
          }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        
        
        ThickDivider()
        
        
        VStack(spacing: 0) {
          MyPageNavigationRow(title: String(localized: "계정 설정"), isDividerPresented: true) {
            router.push(to: .mypage(.accountSetting))
          }
          MyPageInfoRow(title: String(localized: "앱 버전"), value: viewModel.appVersion, isDividerPresented: true)
          MyPageNavigationRow(title: String(localized: "문의 및 고객 지원"), isDividerPresented: true) {
            self.showContactView = true
          }
          MyPageNavigationRow(title: String(localized: "DirAct를 만든 사람들")) {
            router.push(to: .mypage(.appMaker))
          }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        
        
        Spacer()
      }
    }
    .sheet(isPresented: $showContactView) {
      NavigationStack {
        ContactView()
      }
    }
    .notificationToast(
      isPresented: $showContactSucessToast,
      text: String(localized: "소중한 의견이 접수되었습니다.\n조치사항은 로그인 계정으로 안내드리겠습니다."),
      icon: .check,
      for: .toast(.contactSuccess),
      bottomPadding: 16
    )
  }
}


#Preview {
  MyPageView()
    .environmentObject(MyPageViewModel())
}
