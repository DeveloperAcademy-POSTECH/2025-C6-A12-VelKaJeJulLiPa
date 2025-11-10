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
  
  private let privacyPolicyURL = URL(string: "https://mammoth-eyelash-f4f.notion.site/29610840462c8014ba1be32d01ef3edb")!
  
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      
      WebView(url: privacyPolicyURL, isLoading: $isLoading)
        .opacity(isLoading ? 0 : 1)
        .toolbar {
          ToolbarLeadingBackButton(icon: .chevron)
          ToolbarCenterTitle(text: "개인정보처리방침")
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
