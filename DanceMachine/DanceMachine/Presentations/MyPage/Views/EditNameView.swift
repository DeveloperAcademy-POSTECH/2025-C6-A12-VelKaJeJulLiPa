//
//  EditNameView.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import SwiftUI

// FIXME: - Hi-fi 반영
struct EditNameView: View {
    @EnvironmentObject private var router: MainRouter
    
    @State private var viewModel = EditNameViewModel()
    @State private var editedName = ""
    private var isButtonEnabled: Bool { editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || editedName == viewModel.myName ? false : true }
    
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea() // FIXME: - 컬러 수정
            
            VStack {
                Spacer()
                EditNameTextFieldView
                    .padding(.horizontal, 16)
                Spacer()
                bottomButtonView
                    .padding(.horizontal, 16)
            }
        }
        .task {
            editedName = viewModel.myName
        }
        .toolbar {
            ToolbarLeadingBackButton(icon: .chevron)
            ToolbarCenterTitle(text: "나의 이름")
        }
    }
    
    private var EditNameTextFieldView: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(Color.gray.opacity(0.2)) // FIXME: - 컬러 수정
            .frame(maxWidth: .infinity)
            .frame(height: 47) // FIXME: - 버튼 크기 수정
            .overlay {
                TextField("이름을 입력해주세요", text: $editedName)
                    .foregroundStyle(Color.black) // FIXME: - 컬러 수정
                    .multilineTextAlignment(.center)
            }
    }
    
    // MARK: - 이름 수정하기 버튼 뷰
    private var bottomButtonView: some View {
        // FIXME: - 버튼 스타일 수정
        ActionButton(
            title: "확인",
            color: isButtonEnabled ? Color.blue : Color.gray,
            height: 47,
            isEnabled: isButtonEnabled
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
