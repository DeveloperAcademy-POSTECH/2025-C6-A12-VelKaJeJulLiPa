//
//  MyPageView.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI
import UserNotifications

struct MyPageView: View {
    
    @EnvironmentObject private var router: NavigationRouter
    
    @State private var viewModel = MyPageViewModel()
    
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea() // FIXME: - 컬러 수정
            
            VStack { // FIXME: - spacing 수정
                //FIXME: - 글자 스타일 수정
                HStack {
                    Text("마이페이지")
                        .font(.title)
                        .foregroundStyle(Color.black) // FIXME: - 컬러 수정
                        .bold()
                    Spacer()
                }
                .padding()
                
                MyPageInfoRow(title: "ID", value: viewModel.myId)
                MyPageNavigationRow(title: "나의 이름", value: viewModel.myName) {
                    router.push(to: .mypage(.editName))
                }
                
                ThickDivider()
                
                MyPageNavigationRow(title: "개인정보처리방침") {
                    router.push(to: .mypage(.privacyPolicy))
                }
                MyPageNavigationRow(title: "서비스 이용약관") {
                    router.push(to: .mypage(.termsOfUse))
                }
                MyPageNavigationRow(title: "알림 수신") {
                    viewModel.openAppSettings()
                }
                
                ThickDivider()
                
                MyPageNavigationRow(title: "계정 설정") {
                    router.push(to: .mypage(.accountSetting))
                }
                
                Spacer()
            }
        }
    }
}


#Preview {
    MyPageView()
        .environmentObject(MyPageViewModel())
}
