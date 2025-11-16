//
//  ToolbarUploadButton.swift
//  DanceMachine
//
//

import SwiftUI

/// 업로드 버튼입니다.
struct ToolbarUploadButton: ToolbarContent {
  var action: () -> Void

  var body: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      Button {
        action()
      } label: {
        Image(.videoUpload)
      }
      .buttonStyle(.borderedProminent)
      .tint(.secondaryAlternativeGlass)
      .environment(\.colorScheme, .light)
    }
  }
}

#Preview {
  NavigationStack {
    Text("Preview")
      .toolbar {
        ToolbarUploadButton {
          print("Upload tapped")
        }
      }
  }
}
