//
//  WebView.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import SwiftUI
import WebKit

/// SwiftUI에서 UIKit의 WKWebView를 사용하기 위해 UIViewRepresentable을 채택
struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool  // 웹뷰 로딩 상태를 상위 뷰와 바인딩
    
    private let webView = WKWebView()

    /// WKWebView의 네비게이션 델리게이트를 커스텀 Coordinator로 지정 (로딩 상태 제어용)
    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        
        return webView
    }
    
    /// SwiftUI 뷰가 업데이트될 때 호출. (여기선 반복 load 방지 목적)
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // updateUIView는 비워둠 (반복 load 방지)
    }
    
    /// Coordinator 객체 생성 요청 (델리게이트 역할, UIKit <-> SwiftUI 바인딩)
    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }
    
    /// WKNavigationDelegate 채택 Coordinator 클래스: 웹뷰 로딩 상태 변화 감지 및 전달 역할
    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool  // 바인딩 상태값 참조 (로딩 인디케이터 등 연동)
        
        /// 뷰 초기 생성 시 바인딩 주입
        init(isLoading: Binding<Bool>) {
            _isLoading = isLoading
        }
        
        /// 페이지 로딩 시작 시 로딩 인디케이터 표시
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async { self.isLoading = true }
        }
        
        /// 페이지 로딩 완료 시 로딩 인디케이터 숨김
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async { self.isLoading = false }
        }

        /// 페이지 로딩 실패 시 로딩 인디케이터 숨김 (네트워크 에러 등)
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { self.isLoading = false }
        }
        
        /// 초기 네비게이션(리다이렉트 등) 실패 시 로딩 인디케이터 숨김 (초기에 응답 자체가 없을 때)
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { self.isLoading = false }
        }
    }
}


#Preview {
    @Previewable @State var isLoading: Bool = false
    let url =  URL(string: "https://www.apple.com")!
    
    WebView(url: url, isLoading: $isLoading)
}
