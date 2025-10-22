//
//  NameSettingView.swift
//  DanceMachine
//
//  Created by Paidion on 10/14/25.
//

import SwiftUI
import FirebaseAuth

struct NameSettingView: View {
    @State private var viewModel = NameSettingViewModel()
    @State private var name: String = ""
    @FocusState private var isFocused: Bool
    
    let placeholder = "이름을 입력하세요"
    let fontSize: CGFloat = 32 //FIXME: 폰트 크기 수정
    let maxLength = 15 //FIXME: 입력 제한 길이 수정
    
    var displayText: String { name.isEmpty ? placeholder : name }
    var underlineColor: Color { isFocused ? Color.accentColor : Color(.systemGray4) }
    var underlineWidth: CGFloat {
        let textCount = displayText.count
        let base: CGFloat = fontSize * 0.8
        let minimumWidth = name.isEmpty ? CGFloat(placeholder.count) * base : base
        
        return max(CGFloat(textCount) * base, minimumWidth)
    }
    
    
    var body: some View {
        VStack {
            Spacer()
            Text("만나서 반가워요!")
                .font(.system(size: 24))
            
            //FIXME: 텍스트필드 - Mid-fi Design 반영 (제이콥 확인)
            TextField(displayText, text: $name)
                .focused($isFocused)
                .multilineTextAlignment(.center)
                .font(.system(size: fontSize, weight: .bold))
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
                .onChange(of: name, { oldValue, newValue in
                    if newValue.count > maxLength {
                        name = oldValue
                    }
                })
            
            Spacer()
            
            Text("이름이 정확하신가요?")
            
            // FIXME: 버튼 스타일 수정
            ActionButton(
                title: "확인",
                color: Color.blue,
                height: 47,
                isEnabled: !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ) {
                Task {
                    await viewModel.updateUserName(name: name)
                    dismissKeyboard()
                    viewModel.setNeedsNameSettingToFalse()
                }
            }
            .padding()
        }
        .onAppear {
            name = viewModel.displayName
        }
        .dismissKeyboardOnTap()
    }
}

#Preview {
    NameSettingView()
}
