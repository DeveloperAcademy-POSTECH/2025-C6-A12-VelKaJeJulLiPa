//
//  EditNameView.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import SwiftUI

struct EditNameView: View {
    
    @EnvironmentObject private var router: NavigationRouter
    
    @State private var viewModel = EditNameViewModel()
    @State private var editedName = ""
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                EditNameTextFieldView
                Spacer()
                bottomButtonView
            }
        }
        .onAppear {
            editedName = viewModel.myName
        }
        .padding(.horizontal, 16)
        .toolbar {
            ToolbarLeadingBackButton()
            ToolbarCenterTitle(text: "나의 이름")
        }
    }
    
    
    private var EditNameTextFieldView: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(Color.gray.opacity(0.2)) // FIXME: - 컬러 수정
            .frame(maxWidth: .infinity)
            .frame(height: 47) //FIXME: - 버튼 크기 수정
            .overlay {
                TextField("이름을 입력해주세요", text: $editedName)
                    .multilineTextAlignment(.center)
            }
    }
    
    
    // MARK: - 이름 수정하기 버튼 뷰
    private var bottomButtonView: some View {
        // FIXME: - 버튼 스타일 수정
        ActionButton(
            title: "확인",
            color: self.editedName.isEmpty ? Color.gray : Color.blue,
            height: 47,
            isEnabled: self.editedName.isEmpty || editedName == viewModel.myName ? false : true
        ) {
            Task {
                try await self.viewModel.updateMyNameAndReload(
                    userId: FirebaseAuthManager.shared.userInfo?.userId ?? "",
                    newName: editedName
                )
                dismissKeyboard()
                await MainActor.run { router.pop() }
            }
            
        }
    }
    
    
    
}

#Preview {
    NavigationStack {
        EditNameView()
    }
}
