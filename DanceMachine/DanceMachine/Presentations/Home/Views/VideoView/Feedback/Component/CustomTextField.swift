//
//  CustomTextField.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/28/25.
//

import SwiftUI

struct CustomTextField: View {
  @Binding var content: String
  @FocusState private var isFocused: Bool
  
  let placeHolder: String
  let submitAction: () -> Void
  let onFocusChange: ((Bool) -> Void)?
  let autoFocus: Bool
  
  var body: some View {
    VStack(spacing: 8) {
      TextEditor(text: $content)
        .foregroundStyle(.white)
        .scrollContentBackground(.hidden)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .padding(.trailing, 30)
        .focused($isFocused)
        .frame(height: 49)
        .overlay {
          RoundedRectangle(cornerRadius: 20)
            .stroke(Color.white, lineWidth: 2) // FIXME: 스트로크 수정
            .allowsHitTesting(false)
        }
        .overlay(alignment: .leading) {
          if content.isEmpty {
            Text(placeHolder)
              .padding(.horizontal, 16)
              .foregroundStyle(Color.white)
              .allowsHitTesting(false)
          }
        }
        .overlay(alignment: .trailing) {
          Button {
            submitAction()
            self.isFocused = false
          } label: {
            Image(systemName: "paperplane.fill")
              .foregroundStyle(.white)
          }
          .padding(.horizontal, 16)
          .zIndex(1)
        }
        .onChange(of: isFocused) { _, newValue in  // ← 추가
          onFocusChange?(newValue)
        }
    }
    .onAppear {
      if self.autoFocus {
        self.isFocused = true
      }
    }
  }
}

//#Preview {
//  CustomTextField(content: .constant(""), placeHolder: "dd", submitAction: {})
//}
