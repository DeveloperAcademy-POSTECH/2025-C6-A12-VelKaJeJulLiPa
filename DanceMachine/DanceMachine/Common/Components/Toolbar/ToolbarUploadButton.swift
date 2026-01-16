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
      if #available(iOS 26.0, *) {
        Button {
//          action()
        } label: {
          Image(.videoUpload)
            .simultaneousGesture(
              TapGesture()
                .onEnded {
                  action()
                }
            )
        }
        .buttonStyle(.borderedProminent)
        .tint(.secondaryAlternativeGlass)
        .environment(\.colorScheme, .light)
      } else {
        Button {
//          action()
        } label: {
          ZStack {
            Circle().fill(Color.secondaryNormal)
              .frame(width: 44, height: 44)
            Image(.videoUpload)
          }
          .simultaneousGesture(
            TapGesture()
              .onEnded {
                action()
              }
          )
        }
        .environment(\.colorScheme, .light)
      }
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
