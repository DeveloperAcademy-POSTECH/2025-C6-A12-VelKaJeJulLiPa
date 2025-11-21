//
//  NameSettingView.swift
//  DanceMachine
//
//  Created by Paidion on 10/14/25.
//

import SwiftUI
import FirebaseAuth

struct NameSettingView: View {
  @EnvironmentObject private var router: AuthRouter
  @State private var viewModel = NameSettingViewModel()
  @State private var name: String = ""
  @State private var showToastMessage: Bool = false
  @FocusState private var isFocused: Bool
  
  let placeholder = "이름을 입력하세요"
  let fontSize: CGFloat = 32
  let maxLength = 10
  
  var displayText: String { name.isEmpty ? placeholder : name }
  var underlineColor: Color {
    displayText.count >= maxLength ? Color.accentRedNormal : isFocused ? Color.secondaryNormal : Color.labelNormal
  }
  var underlineWidth: CGFloat {
    let textCount = displayText.count
    let base: CGFloat = fontSize * 0.8
    let minimumWidth = name.isEmpty ? CGFloat(placeholder.count) * base : base
    
    return max(CGFloat(textCount) * base, minimumWidth)
  }
  
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      
      VStack {
        Spacer()
        Text("만나서 반가워요!")
          .font(.title2SemiBold)
          .foregroundStyle(Color.labelNormal)
        
        TextField(
          text: $name,
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
        .onChange(of: name) { oldValue, newValue in
          var updated = newValue
          
          if updated.first == " " {
            updated = String(updated.drop(while: { $0 == " " }))
          }
          
          if updated.count > maxLength {
            updated = String(updated.prefix(maxLength))
            showToastMessage = true
            HapticManager.shared.trigger(.medium)
          }
          
          if updated != name {
            name = updated
          }
        }
        
        Spacer()
        
        Text("이름이 정확한가요?")
          .font(.headline2Medium)
          .foregroundStyle(Color.labelNormal)
        
        ActionButton(
          title: "확인",
          color: Color.secondaryNormal,
          height: 47,
          isEnabled: !name
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading,
          isLoading: viewModel.isLoading
        ) {
          Task {
            try await viewModel.createNewuser()
            dismissKeyboard()
            viewModel.completeNameSetting()
          }
        }
        .padding()
      }
    }
    .onAppear {
      name = viewModel.displayName
    }
    .onDisappear {
      router.destination.removeAll()
    }
    .toast(
      isPresented: $showToastMessage,
      duration: 2,
      position: .bottom,
      bottomPadding: 16 + 47 + 16 // 아래 빈공간 + 버튼 크기 + 윗 빈공간
    ) {
      ToastView(text: "이름은 10자 이내로 입력해주세요.", icon: .warning)
    }
    .dismissKeyboardOnTap()
    .background(
      DisableSwipeBackGesture()
        .allowsHitTesting(false)
    )
  }
}

#Preview {
  NameSettingView()
}
