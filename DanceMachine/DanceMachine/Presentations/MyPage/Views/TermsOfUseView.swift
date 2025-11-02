//
//  TermsOfUseView.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import SwiftUI

struct TermsOfUseView: View {
    @State private var isLoading = false
    
    private let termsOfUseURL = URL(string: "https://mammoth-eyelash-f4f.notion.site/29610840462c8038a85bf08362518b03?source=copy_link")!
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()  // FIXME: - 컬러 수정
            
            WebView(url: termsOfUseURL, isLoading: $isLoading)
                .opacity(isLoading ? 0 : 1)
                .toolbar {
                    ToolbarLeadingBackButton(icon: .chevron)
                    ToolbarCenterTitle(text: "서비스 이용약관")
                }
            
            if isLoading {
                ProgressView()
            }
        }
        
        
    }
}


#Preview {
    TermsOfUseView()
}
