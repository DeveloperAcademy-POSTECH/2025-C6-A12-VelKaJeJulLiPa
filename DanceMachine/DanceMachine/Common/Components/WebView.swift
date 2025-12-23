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

  /// WKWebView 생성
  func makeUIView(context: Context) -> WKWebView {
    webView.navigationDelegate = context.coordinator
    webView.load(URLRequest(url: url))
    return webView
  }

  /// SwiftUI 뷰 업데이트 시 호출 (반복 load 방지)
  func updateUIView(_ uiView: WKWebView, context: Context) {
    // intentionally left empty
  }

  /// Coordinator 생성
  func makeCoordinator() -> Coordinator {
    Coordinator(isLoading: $isLoading)
  }

  // MARK: - Coordinator

  final class Coordinator: NSObject, WKNavigationDelegate {
    @Binding var isLoading: Bool

    init(isLoading: Binding<Bool>) {
      _isLoading = isLoading
    }

    /// 페이지 로딩 시작
    func webView(
      _ webView: WKWebView,
      didStartProvisionalNavigation navigation: WKNavigation?
    ) {
      DispatchQueue.main.async {
        self.isLoading = true
      }
    }

    /// 페이지 로딩 완료
    func webView(
      _ webView: WKWebView,
      didFinish navigation: WKNavigation?
    ) {
      DispatchQueue.main.async {
        self.isLoading = false
      }
    }

    /// 페이지 로딩 실패
    func webView(
      _ webView: WKWebView,
      didFail navigation: WKNavigation?,
      withError error: Error
    ) {
      DispatchQueue.main.async {
        self.isLoading = false
      }
    }

    /// 초기 네비게이션 실패 (리다이렉트, 네트워크 문제 등)
    func webView(
      _ webView: WKWebView,
      didFailProvisionalNavigation navigation: WKNavigation?,
      withError error: Error
    ) {
      DispatchQueue.main.async {
        self.isLoading = false
      }
    }
  }
}

// MARK: - Preview

#Preview {
  @Previewable @State var isLoading = false

  let url = URL(string: "https://www.apple.com")
    ?? URL(fileURLWithPath: "/")

  WebView(url: url, isLoading: $isLoading)
}
