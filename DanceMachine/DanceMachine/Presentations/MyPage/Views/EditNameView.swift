//
//  EditNameView.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import SwiftUI

struct EditNameView: View {
  @EnvironmentObject private var router: MainRouter
  
  @State private var viewModel = EditNameViewModel()
  @State private var editedName = ""
  @State private var showToastMessage: Bool = false
  @State private var isAlertPresented: Bool = false
  @FocusState private var isFocused: Bool
  private var isButtonEnabled: Bool {
    editedName
      .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || editedName == viewModel.myName ? false : true
  }
  
  let placeholder = "이름을 입력하세요"
  let fontSize: CGFloat = 32
  let maxLength = 10
  
  var displayText: String { editedName.isEmpty ? placeholder : editedName }
  var underlineColor: Color {
    displayText.count >= maxLength ? Color.accentRedNormal : isFocused ? Color.secondaryNormal : Color.labelNormal
  }
  var underlineWidth: CGFloat {
    let textCount = displayText.count
    let base: CGFloat = fontSize * 0.8
    let minimumWidth = editedName.isEmpty ? CGFloat(placeholder.count) * base : base
    
    return max(CGFloat(textCount) * base, minimumWidth)
  }
  
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      
      VStack {
        Spacer()
        
        TextField(
          text: $editedName,
          prompt: Text(displayText).foregroundStyle(.labelAssitive)
        ) {
          Text("사용자 이름")
        }
        .focused($isFocused)
        .multilineTextAlignment(.center)
        .font(.title1SemiBold)
        .tint(.secondaryNormal)
        .foregroundStyle(Color.labelStrong)
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)
        .overlay {
          Rectangle()
            .offset(y: 26)
            .frame(height: 2)
            .frame(width: underlineWidth)
            .foregroundStyle(underlineColor)
            .animation(.easeInOut(duration: 0.1), value: underlineWidth)
        }
        .onChange(of: editedName) { oldValue, newValue in
          var updated = newValue
          
          if updated.first == " " {
            updated = String(updated.drop(while: { $0 == " " }))
          }
          
          if updated.count > maxLength {
            updated = String(updated.prefix(maxLength))
            showToastMessage = true
            HapticManager.shared.trigger(.medium)
          }
          
          if updated != editedName {
            editedName = updated
          }
        }
        
        Spacer()
        bottomButtonView
          .padding()
      }
    }
    .task {
      editedName = viewModel.myName
    }
    .toast(
      isPresented: $showToastMessage,
      duration: 2,
      position: .bottom,
      bottomPadding: 16 + 47 + 16 // 아래 빈공간 + 버튼 크기 + 윗 빈공간
    ) {
      ToastView(text: "이름은 10자 이내로 입력해주세요.", icon: .warning)
    }
    .unsavedChangesAlert(
      isPresented: $isAlertPresented,
      onConfirm: { router.pop() }
    )
    .toolbar {
      ToolbarLeadingBackButton(icon: .chevron) {
        if editedName != viewModel.myName {
          dismissKeyboard()
          isAlertPresented = true
        } else {
          router.pop()
        }
      }
      ToolbarCenterTitle(text: "나의 이름 설정")
    }
    .dismissKeyboardOnTap()
  }
  
  
  // MARK: - 이름 수정하기 버튼 뷰
  private var bottomButtonView: some View {
    ActionButton(
      title: "변경하기",
      color: Color.secondaryNormal,
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
