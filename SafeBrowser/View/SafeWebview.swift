//
//  SafeWebview.swift
//  SafeBrowser
//
//  Created by Md Faizul karim on 31/12/24.
//
//
import Foundation
import WebKit
import SwiftUI

struct WebView: UIViewRepresentable {
    let webView: WKWebView
    var onLinkClicked: ((String) -> Void)?
    var onURLChange: ((String) -> Void)? 

    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var shouldLoadURL = false

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            NotificationCenter.default.post(name: .webViewDidUpdateNavigationState, object: nil)
            DispatchQueue.main.async {
                self.parent.onURLChange?("loadingFinished")
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            if let url = webView.url?.absoluteString {
                parent.onURLChange?(url)
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if shouldLoadURL {
                shouldLoadURL = false
                decisionHandler(.allow)
            } else if let url = navigationAction.request.url?.absoluteString {
                parent.onLinkClicked?(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}

extension Notification.Name {
    static let webViewDidUpdateNavigationState = Notification.Name("webViewDidUpdateNavigationState")
}
