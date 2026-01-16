//
//  PrivacyPolicyView.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import SwiftUI
import WebKit

struct PrivacyPolicyView: View {
  
  @State private var isLoading: Bool = true
  
  private var privacyPolicyURL: URL? {
    URL(string: PrivacyPolicy.current.privacyPolicyURL)
  }
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      
      if let url = privacyPolicyURL {
        WebView(url: url, isLoading: $isLoading)
          .opacity(isLoading ? 0 : 1)
          .toolbar {
            ToolbarLeadingBackButton(icon: .chevron)
            ToolbarCenterTitle(text: String(localized: "개인정보처리방침"))
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
  PrivacyPolicyView()
}
