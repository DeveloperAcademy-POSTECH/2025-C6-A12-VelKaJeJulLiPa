//
//  AccountSettingView.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import SwiftUI

struct AccountSettingView: View {
    
    @EnvironmentObject private var router: NavigationRouter
    
    @State private var viewModel = AccountSettingViewModel()
    
    @State private var isPresentingSignOutSheet: Bool = false     // 로그아웃 시트 제어
    @State private var isPresentingDeleteUserSheet: Bool = false  // 회원탈퇴 시트 제어
    
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground) // FIXME: - 컬러 수정
                .ignoresSafeArea()
            
            VStack {
                MyPageInfoRow(
                    title: "ID",
                    value: viewModel.myId
                )
                
                Spacer()
                
                ActionButton(
                    title: "로그아웃",
                    color: Color.orange, // FIXME: - 컬러 수정
                    height: 47,
                    action: { isPresentingSignOutSheet = true }
                )
                .padding()
                
                Button {
                    isPresentingDeleteUserSheet = true
                } label: {
                    Text("회원탈퇴")
                        .foregroundStyle(.red) // FIXME: - 컬러 수정
                }
            }
        }
        .sheet(isPresented: $isPresentingSignOutSheet) {
            BottomConfirmSheetView(
                titleText: "로그아웃하시겠어요?",
                primaryText: "로그아웃") {
                    Task {
                        try viewModel.signOut()
                        router.popToRootView()
                    }
                }
        }
        .sheet(isPresented: $isPresentingDeleteUserSheet) {
            BottomConfirmSheetView(
                titleText: "탈퇴하시겠어요?\n모든 정보가 삭제됩니다.",
                primaryText: "탈퇴") {
                    Task {
                        try await viewModel.deleteUserAccount()
                        router.popToRootView() // FIXME: - 내비게이션 처리 확인
                    }
                }
        }
        .toolbar {
          ToolbarLeadingBackButton(icon: .chevron)
            ToolbarCenterTitle(text: "계정 설정")
        }
        
    }
}



#Preview {
    AccountSettingView()
}



