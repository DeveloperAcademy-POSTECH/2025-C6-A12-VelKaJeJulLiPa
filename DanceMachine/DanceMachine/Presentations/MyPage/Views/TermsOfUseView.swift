//
//  TermsOfUseView.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import SwiftUI

struct TermsOfUseView: View {
  @State private var isLoading = false
  
  private var termsOfUseURL: URL? {
    URL(string: PrivacyPolicy.current.termsAgreeURL)
  }
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      
      if let url = termsOfUseURL {
        WebView(url: url, isLoading: $isLoading)
          .opacity(isLoading ? 0 : 1)
          .toolbar {
            ToolbarLeadingBackButton(icon: .chevron)
            ToolbarCenterTitle(text: String(localized: "서비스 이용약관"))
          }
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
