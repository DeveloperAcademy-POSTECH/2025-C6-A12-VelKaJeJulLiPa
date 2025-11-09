//
//  CustomTextField.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/28/25.
//

import SwiftUI
import UIKit

struct CustomTextField: View {
  @Binding var content: String

  let placeHolder: String
  let submitAction: () -> Void
  let onFocusChange: ((Bool) -> Void)?
  let autoFocus: Bool

  @State private var textHeight: CGFloat = 49
  @State private var isFocused: Bool = false

  var body: some View {
    VStack(spacing: 8) {
      DynamicTextView(
        text: $content,
        height: $textHeight,
        isFocused: $isFocused
      )
      .frame(height: textHeight)
      .overlay {
        RoundedRectangle(cornerRadius: 20)
          .stroke(Color.strokeStrong, lineWidth: 1)
          .allowsHitTesting(false)
      }
      .overlay(alignment: .topLeading) {
        if content.isEmpty {
          Text(placeHolder)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .foregroundStyle(.labelAssitive)
            .allowsHitTesting(false)
        }
      }
      .overlay(alignment: .trailing) {
        Button {
          submitAction()
          self.isFocused = false
        } label: {
          Image(systemName: "paperplane.fill")
            .font(.system(size: 19))
            .foregroundStyle(.fillAssitive)
        }
        .padding(.horizontal, 16)
        .zIndex(1)
      }
      .onChange(of: isFocused) { _, newValue in
        onFocusChange?(newValue)
      }
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

// UITextView를 사용한 동적 높이 TextEditor
struct DynamicTextView: UIViewRepresentable {
  @Binding var text: String
  @Binding var height: CGFloat
  @Binding var isFocused: Bool

  private let minHeight: CGFloat = 49
  private let maxHeight: CGFloat = 120

  func makeUIView(context: Context) -> UITextView {
    let textView = UITextView()
    textView.delegate = context.coordinator
    textView.font = .systemFont(ofSize: 17)
    textView.backgroundColor = .clear
    textView.textColor = UIColor(Color.labelStrong)
    textView.textContainerInset = UIEdgeInsets(top: 15, left: 14, bottom: 6, right: 40)
    textView.textContainer.lineFragmentPadding = 0
    textView.isScrollEnabled = false
    textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    return textView
  }

  func updateUIView(_ textView: UITextView, context: Context) {
    if textView.text != text {
      textView.text = text
    }

    if isFocused && !textView.isFirstResponder {
      textView.becomeFirstResponder()
    } else if !isFocused && textView.isFirstResponder {
      textView.resignFirstResponder()
    }

    // 높이 업데이트는 다음 런루프에서 처리
    Task { @MainActor in
      self.updateHeight(textView)
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  private func updateHeight(_ textView: UITextView) {
    let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .infinity))
    let newHeight = min(max(size.height, minHeight), maxHeight)

    if newHeight != height {
      withAnimation(.easeInOut(duration: 0.2)) {
        self.height = newHeight
      }
    }

    textView.isScrollEnabled = newHeight >= maxHeight
  }

  class Coordinator: NSObject, UITextViewDelegate {
    let parent: DynamicTextView

    init(_ parent: DynamicTextView) {
      self.parent = parent
    }

    func textViewDidChange(_ textView: UITextView) {
      Task { @MainActor in
        self.parent.text = textView.text
        self.parent.updateHeight(textView)
      }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
      Task { @MainActor in
        self.parent.isFocused = true
      }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
      Task { @MainActor in
        self.parent.isFocused = false
      }
    }
  }
}

//#Preview {
//  CustomTextField(content: .constant(""), placeHolder: "dd", submitAction: {})
//}
