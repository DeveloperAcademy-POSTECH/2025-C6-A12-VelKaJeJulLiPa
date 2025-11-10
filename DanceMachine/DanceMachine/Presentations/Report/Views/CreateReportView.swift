//
//  CreateReportView.swift
//  DanceMachine
//
//  Created by Paidion on 11/8/25.
//

import SwiftUI

struct CreateReportView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel = CreateReportViewModel()

  @State var description: String = ""
  @FocusState private var isFocusTextField: Bool
  @State private var showExitAlert: Bool = false

  var reportedId: String
  var reportContentType: ReportContentType
  var video: Video? = nil
  var feedback: Feedback? = nil
  var reply: Reply? = nil
  var toastReceiveView: ReportToastReceiveViewType
  
  var maxLength: Int = 100 // 최대 글자수
  var isInvalid: Bool { description.count == maxLength ? true : false }
  var inputHelperText: String {
    isInvalid ? "100자 미만으로 입력해주세요." : "\(description.count)/\(maxLength)"
  }

  
  var body: some View {
    VStack(spacing: 0) {
      Text("신고 사유를 작성해주세요.")
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
    .toolbar {
      ToolbarLeadingBackButton(icon: .xmark) {
        if !description.isEmpty {
          self.showExitAlert = true
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
  }
  
  
  // MARK: - 하단 신고하기 버튼 뷰
  private var bottomButtonView: some View {
    ActionButton(
      title: "확인",
      color: description.isEmpty ? Color.fillAssitive : Color.secondaryStrong,
      height: 47,
      isEnabled: description.isEmpty ? false : true
    ) {
      // FIXME: 신고 정보 서버에 저장 + 성공 Toast 메시지 보여주기
      Task {
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
        await MainActor.run { dismiss() }
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
    CreateReportView(reportedId: "", reportContentType: .video, video: video, toastReceiveView: ReportToastReceiveViewType.videoListView)
  }
}


struct MultilineTextField: View {
  @Binding var text: String
  @FocusState.Binding var isFocused: Bool
  
  var maxLength: Int = 100
  var cornerRadius: CGFloat = 15
  
  var body: some View {
    ZStack {
      // MARK: - 텍스트필드
      TextField(
        text.isEmpty && !isFocused ? "신고 사유를 입력해주세요." : "",
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
      .onChange(of: text) { oldValue, newValue in
        let updated = newValue.sanitized(limit: maxLength)
        if updated != text {
          text = updated
        }
      }
      
      // MARK: - 텍스트필드 배경 + border
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(Color.fillStrong)
          .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
              .stroke(
                text.count >= maxLength ? Color.accentRedNormal : Color.secondaryStrong,
                lineWidth: isFocused ? 1 : 0)
          )
      )
      
      // MARK: - 텍스트필드 초기화 버튼
      .overlay(alignment: .bottomTrailing) {
        if !text.isEmpty {
          Button {
            text = ""
          } label: {
            Image(systemName: "xmark.circle.fill")
              .frame(width: 44,   height: 44)
              .foregroundStyle(Color.labelNormal)
          }
        }
      }
      
      //FIXME: 텍스트 필드 내부 글자수 인디케이터 - 디자인 논의 후 처리하기
      //      .overlay(alignment: .bottom) {
      //        ZStack {
      //          Text("\(text.count)/\(maxLength)")
      //            .font(.headline2Medium)
      //            .foregroundStyle(Color.secondaryStrong)
      //
      //          HStack {
      //            Spacer()
      //            if !text.isEmpty {
      //              Button {
      //                text = ""
      //              } label: {
      //                Image(systemName: "xmark.circle.fill")
      //                  .font(.system(size: 16))
      //                  .foregroundStyle(Color.labelNormal)
      //              }
      //              .frame(width: 44, height: 44)
      //            }
      //          }
      //        }
      //        .frame(maxWidth: .infinity)
      //      }
      
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
