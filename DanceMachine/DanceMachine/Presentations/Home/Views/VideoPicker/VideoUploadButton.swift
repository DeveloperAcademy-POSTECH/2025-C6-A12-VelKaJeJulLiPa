//
//  VideoUploadButton.swift
//  DanceMachine
//
//  Created by Claude on 11/24/25.
//

import SwiftUI

struct VideoUploadButton: View {
  let isDisabled: Bool
  let action: () -> Void

  var body: some View {
    if #available(iOS 26.0, *) {
      Button {
        action()
      } label: {
        Image(systemName: "arrow.up")
          .foregroundStyle(
            isDisabled ? Color.labelAssitive : Color.labelStrong
          )
      }
      .disabled(isDisabled)
      .buttonStyle(.borderedProminent)
      .tint(Color.secondaryStrong)
      .environment(\.colorScheme, .light)
    } else {
      Button {
        action()
      } label: {
        ZStack {
          Circle().fill(Color.secondaryNormal)
            .frame(width: 44, height: 44)
          Image(systemName: "arrow.up")
            .foregroundStyle(
              isDisabled ? Color.labelAssitive : Color.labelStrong
            )
        }
      }
      .disabled(isDisabled)
      .environment(\.colorScheme, .light)
    }
  }
}
