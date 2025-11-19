//
//  CreateReportView.swift
//  DanceMachine
//
//  Created by Paidion on 11/8/25.
//

import SwiftUI
import MessageUI

struct CreateReportView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel = CreateReportViewModel()
  
  @State var description: String = ""
  @FocusState private var isFocusTextField: Bool
  @State private var needToCreateReport: Bool = false
  @State private var showMailSheet: Bool = false
  @State private var showExitAlert: Bool = false
  @State private var showMailSendFailedAlert: Bool = false
  @State private var showCreateReportFailedAlert: Bool = false
  
  var reportedId: String
  var reportContentType: ReportContentType
  var video: Video? = nil
  var feedback: Feedback? = nil
  var reply: Reply? = nil
  var toastReceiveView: ReportToastReceiveViewType
  
  var maxLength: Int = 100 // 최대 글자수
  var isInvalid: Bool { description.count == maxLength }
  var inputHelperText: String {
    isInvalid ? "100자 미만으로 입력해 주세요." : "\(description.count)/\(maxLength)"
  }
  
  let username = FirebaseAuthManager.shared.userInfo?.name ?? "Unknown"
  var subject: String { "[신고] - \(username)님의 신고" }
  var targetContentId: String {
    switch reportContentType {
    case .feedback:
      return feedback?.id ?? ""
    case .reply:
      return reply?.id ?? ""
    case .video:
      return video?.id ?? ""
    }
  }
  
  var mailBody: String {
    """
    신고자 정보
    • 사용자 ID: \(FirebaseAuthManager.shared.userInfo?.userId ?? "Unknown")
    • 이메일: \(FirebaseAuthManager.shared.userInfo?.email ?? "이메일을 입력해주세요")
    
    신고정보
    • 신고유형: \(reportContentType.rawValue)
    • 콘텐츠 ID: \(targetContentId)
    • 신고 사유: \(description)
    """
  }
  
  // MARK: - Body
  var body: some View {
    VStack(spacing: 0) {
      Text("신고 사유를 작성해 주세요.")
        .font(.title2SemiBold)
        .foregroundStyle(Color.labelStrong)
      
      Spacer().frame(height: 32)
      
      MultilineTextField(text: $description, isFocused: $isFocusTextField)
        .padding(.horizontal, 16)
      
      Spacer().frame(height: 16)
      Text(inputHelperText)
        .font(.headline2Medium)
        .foregroundStyle(isInvalid ? Color.accentRedNormal : Color.secondaryNormal)
        .opacity(description.isEmpty ? 0 : 1)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.backgroundElevated)
    .dismissKeyboardOnTap()
    .safeAreaInset(edge: .bottom) {
      bottomButtonView
        .padding(.all, 16)
    }
    .sheet(
      isPresented: $showMailSheet,
      onDismiss: {
        if showMailSendFailedAlert { return }
        if needToCreateReport {
          submitReport()
        }
        dismiss()
      },
      content: {
        MailView(
          needToCreateReport: $needToCreateReport,
          showMailSendFailedAlert: $showMailSendFailedAlert,
          subject: subject,
          body: mailBody
        )
      }
    )
    .toolbar {
      ToolbarLeadingBackButton(icon: .xmark) {
        if !description.isEmpty {
          showExitAlert = true
        } else {
          dismiss()
        }
      }
      ToolbarCenterTitle(text: "신고하기")
    }
    .unsavedChangesAlert(
      isPresented: $showExitAlert,
      onConfirm: {
        dismissKeyboard()
        dismiss()
      }
    )
    .alert(
      "신고 메일을 보내는데 실패했습니다.",
      isPresented: $showMailSendFailedAlert
    ) {
      Button("확인", role: .cancel) {}
    } message: {
        Text("잠시 후 다시 시도해 주세요.")
    }
    .alert(
      "신고 정보를 서버에 저장하는데 실패했습니다.",
      isPresented: $showCreateReportFailedAlert
    ) {
      Button("확인", role: .cancel) {}
    } message: {
        Text("잠시 후 다시 시도해 주세요.")
    }
  }

  // MARK: - 하단 신고하기 버튼 뷰
  private var bottomButtonView: some View {
    ActionButton(
      title: "확인",
      color: description.isEmpty ? Color.fillAssitive : Color.secondaryStrong,
      height: 47,
      isEnabled: !description.isEmpty
    ) {
      if MFMailComposeViewController.canSendMail() {
        showMailSheet = true
      } else {
        submitReport()
      }
    }
  }

  // MARK: - 신고 저장하기
  private func submitReport() {
    Task {
      do {
        try await viewModel.createReport(
          reportedId: reportedId,
          video: video,
          feedback: feedback,
          reply: reply,
          type: ReportType.other,
          reportContentType: reportContentType,
          description: description
        )
        
        NotificationCenter.default.post(
          name: .showCreateReportSuccessToast,
          object: nil,
          userInfo: ["toastViewName": toastReceiveView]
        )
        
        dismiss()
      } catch {
        showCreateReportFailedAlert = true
      }
    }
  }
}

#Preview {
  @Previewable let video = Video(
    videoId: UUID(),
    videoTitle: "벨코의 리치맨",
    videoDuration: 20.0,
    videoURL: "",
    thumbnailURL: "",
    uploaderId: ""
  )
  
  NavigationStack {
    CreateReportView(
      reportedId: "",
      reportContentType: .video,
      video: video,
      toastReceiveView: ReportToastReceiveViewType.videoListView
    )
  }
}


struct MultilineTextField: View {
  @Binding var text: String
  @FocusState.Binding var isFocused: Bool
  
  var maxLength: Int = 100
  var cornerRadius: CGFloat = 15
  
  var body: some View {
    ZStack {
      TextField(
        text.isEmpty && !isFocused ? "신고 사유를 입력해 주세요." : "",
        text: $text,
        axis: .vertical
      )
      .tint(Color.secondaryStrong)
      .font(.body1Medium)
      .foregroundStyle(Color.labelStrong)
      .multilineTextAlignment(.center)
      .lineSpacing(8)
      .padding(.all, 16)
      .focused($isFocused)
      .onChange(of: text) { _, newValue in
        let updated = newValue.sanitized(limit: maxLength)
        if updated != text { text = updated }
      }
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(Color.fillStrong)
          .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
              .stroke(
                text.count >= maxLength ? Color.accentRedNormal : Color.secondaryStrong,
                lineWidth: isFocused ? 1 : 0
              )
          )
      )
      .overlay(alignment: .bottomTrailing) {
        if !text.isEmpty {
          Button {
            text = ""
          } label: {
            Image(systemName: "xmark.circle.fill")
              .frame(width: 44, height: 44)
              .foregroundStyle(Color.labelNormal)
          }
        }
      }
    }
  }
}

#Preview {
  PreviewWrapper()
}

private struct PreviewWrapper: View {
  @State private var text1 = ""
  @State private var text2 = "이건 테스트 문장입니다. TextField 내부에서 여러 줄로 작성할 수 있습니다."
  @FocusState private var isFocused: Bool
  
  var body: some View {
    NavigationStack {
      ZStack {
        Color.backgroundNormal.ignoresSafeArea()
        VStack(spacing: 20) {
          MultilineTextField(text: $text1, isFocused: $isFocused)
          MultilineTextField(text: $text2, isFocused: $isFocused)
        }
        .padding()
      }
    }
  }
}
