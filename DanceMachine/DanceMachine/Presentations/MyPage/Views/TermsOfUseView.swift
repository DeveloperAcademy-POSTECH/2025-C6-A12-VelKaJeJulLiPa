//
//  TermsOfUseView.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import SwiftUI

struct TermsOfUseView: View {
  @State private var isLoading = true

  private var termsOfUseURL: URL? {
    URL(string: "https://mammoth-eyelash-f4f.notion.site/29610840462c8014ba1be32d01ef3edb")
  }

  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()

      if let url = termsOfUseURL {
        WebView(url: url, isLoading: $isLoading)
          .opacity(isLoading ? 0 : 1)
          .toolbar {
            ToolbarLeadingBackButton(icon: .chevron)
            ToolbarCenterTitle(text: "서비스 이용약관")
          }
      } else {
        EmptyView()
      }

      if isLoading {
        LoadingSpinner()
          .frame(maxWidth: 28, maxHeight: 28, alignment: .center)
      }
    }
  }
}

#Preview {
  TermsOfUseView()
}
