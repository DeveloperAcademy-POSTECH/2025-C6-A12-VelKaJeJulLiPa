//
//  ContactView.swift
//  DanceMachine
//
//  Created by 조재훈 on 12/31/25.
//

import SwiftUI
import FirebaseFirestore

struct ContactView: View {
  @Environment(\.dismiss) private var dismiss

  @State var description: String = ""
  @FocusState private var isFocusTextField: Bool
  @State private var isLoading: Bool = false
  @State private var showSuccessToast: Bool = false
  @State private var showError: Bool = false
  
  var isInvalid: Bool { description.count == 100 }
  var inputHelperText: String {
    isInvalid ? String(localized: "100자 미만으로 입력해 주세요.") : "\(description.count)/\(100)"
  }
  
  let username = FirebaseAuthManager.shared.userInfo?.name ?? "알 수 없음"
  
  var body: some View {
    VStack(spacing: 0) {
      Text("문의 및 제보 사항을 작성해 주세요.")
        .font(.title2SemiBold)
        .foregroundStyle(Color.labelStrong)
      
      Spacer().frame(height: 32)
      
      MultilineTextField(text: $description, isFocused: $isFocusTextField, placeHolder: String(localized: "작은 피드백이라도 큰 힘이 됩니다."))
        .padding(.horizontal, 16)
      
      Spacer().frame(height: 16)
      Text(inputHelperText)
        .font(.headline2Medium)
        .foregroundStyle(isInvalid ? Color.accentRedNormal : Color.secondaryNormal)
        .opacity(description.isEmpty ? 0 : 1)
    }
    .toolbar {
      ToolbarLeadingBackButton(icon: .chevron)
      ToolbarCenterTitle(text: String(localized: "문의 및 고객 지원"))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.backgroundElevated)
    .dismissKeyboardOnTap()
    .safeAreaInset(edge: .bottom) {
      bottomButtonView
        .padding(.all, 16)
    }
    .toast(
      isPresented: $showError,
      duration: 2,
      position: .bottom,
      bottomPadding: 16,
      content: {
        ToastView(
          text: String(localized: "문제가 발생했습니다."),
          icon: .warning
        )
      }
    )
  }
  
  private var bottomButtonView: some View {
    ActionButton(
      title: String(localized: "접수하기"),
      color: description.isEmpty ? Color.fillAssitive : Color.secondaryStrong,
      height: 47,
      isEnabled: !description.isEmpty && !isLoading
    ) {
      Task {
        await sendInquiry()
      }
    }
  }

  private func sendInquiry() async {
    guard let userId = FirebaseAuthManager.shared.userInfo?.userId else {
      showError = true
      return
    }

    isLoading = true

    do {
      let inquiry: [String: Any] = [
        "userId": userId,
        "content": description,
        "createdAt": Timestamp(),
        "status": "pending"
      ]

      try await Firestore.firestore()
        .collection("inquiries")
        .addDocument(data: inquiry)

      // 성공
      description = ""
      dismiss()
      NotificationCenter.post(.toast(.contactSuccess))
    } catch {
      print("Error sending inquiry: \(error.localizedDescription)")
      showError = true
    }

    isLoading = false
  }
}

#Preview {
  NavigationStack {
    ContactView()
  }
}
