//
//  CustomTextField.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/28/25.
//

import SwiftUI

struct CustomTextField: View {
  @Binding var content: String
  
  let placeHolder: String
  let submitAction: () -> Void
  let onFocusChange: ((Bool) -> Void)?
  let autoFocus: Bool
  
  @FocusState private var isFocused: Bool   // 실제 포커스 상태
  
  var body: some View {
    ZStack(alignment: .trailing) {
      TextField(placeHolder, text: $content, axis: .vertical)
        .focused($isFocused)
        .font(.headline2Medium)
        .foregroundStyle(Color.labelStrong)
        .textInputAutocapitalization(.sentences)
        .autocorrectionDisabled(false)
        .padding(.leading, 16)
        .padding(.vertical, 12)
        .padding(.trailing, 40)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(Color.fillStrong)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 20)
            .stroke(Color.strokeStrong, lineWidth: 1)
        )
      
      Button {
        submitAction()
        isFocused = false
      } label: {
        Image(systemName: "paperplane.fill")
          .font(.system(size: 19))
          .foregroundStyle(content.isEmpty ? .fillAssitive : .secondaryStrong)
      }
      .frame(width: 18, height: 18)
      .padding(.trailing, 20)
    }
    .frame(minHeight: 49)
    .onChange(of: isFocused) { _, newValue in
      onFocusChange?(newValue)
    }
    .onAppear {
      if autoFocus {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          isFocused = true
        }
      }
    }
  }
}

//#Preview {
//  CustomTextField(content: .constant(""), placeHolder: "dd", submitAction: {})
//}
