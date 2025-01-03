//
//  ContentView.swift
//  SafeBrowser
//
//  Created by Md Faizul karim on 31/12/24.
//
//

import SwiftUI
import WebKit

struct ContentView: View {
    @ObservedObject var viewModel = SafeBrowserViewModel()
    private let webView = WKWebView()
    
    var body: some View {
        NavigationView {
            VStack {
                controlBar
                loadingProgressBar
                WebView(webView: webView, onLinkClicked: handleURLChange, onURLChange: updateURL)
                    .edgesIgnoringSafeArea(.all)
                if viewModel.isBlocked {
                    Text("URL is blocked by the DNS server.")
                        .foregroundColor(.red)
                        .padding()
                }
                Spacer()
            }
            .padding(5)
            .onAppear(perform: attachNavigationObservers)
            .onChange(of: viewModel.dnsAnswer) { newValue in
                if newValue != "" {
                    handleDNSAnswer(newValue)
                    viewModel.dnsAnswer = ""
                }
            }
        }
    }
    
    private var controlBar: some View {
        HStack(spacing: 10) {
            navigationButton(action: goBack, imageName: "chevron.left", isEnabled: viewModel.canGoBack)
            navigationButton(action: goForward, imageName: "chevron.right", isEnabled: viewModel.canGoForward)
            urlTextField
            navigationButton(action: reloadPage, imageName: "arrow.clockwise", isEnabled: true)
        }
        .padding(.horizontal)
    }
    
    private var loadingProgressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(Color.gray.opacity(0.3))
                Rectangle()
                    .frame(width: geometry.size.width * viewModel.animationProgress, height: 2)
                    .foregroundColor(Color.blue)
                    .animation(.linear(duration: 1.0), value: viewModel.animationProgress)
            }
        }
        .padding(.horizontal)
        .frame(height: 2)
        .opacity(viewModel.showAnimation ? 1 : 0)
    }
    
    
    private var urlTextField: some View {
        TextField("", text: $viewModel.urlString, onCommit: viewModel.checkURL)
            .placeholder(when: viewModel.urlString.isEmpty) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    Text("Search")
                        .foregroundColor(.gray)
                }
            }
            .textFieldStyle(PlainTextFieldStyle())
            .padding(6)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .textInputAutocapitalization(.never)
    }
    
    private func navigationButton(action: @escaping () -> Void, imageName: String, isEnabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: imageName)
                .padding(12)
                .background(Color.gray.opacity(0.2))
                .clipShape(Circle())
                .frame(width: 30, height: 30)
        }
        .disabled(!isEnabled)
    }
    
    private func attachNavigationObservers() {
        NotificationCenter.default.addObserver(forName: .webViewDidUpdateNavigationState, object: nil, queue: .main) { _ in
            viewModel.canGoBack = webView.canGoBack
            viewModel.canGoForward = webView.canGoForward
        }
    }
    
    private func handleURLChange(newURL: String) {
        if !newURL.contains("about:blank") {
            startAnimation()
            viewModel.urlString = newURL
            viewModel.checkURL()
        }
    }
    
    private func handleDNSAnswer(_ answer: String) {
        startAnimation()
        if answer == "not found" {
            viewModel.isBlocked = false
            if !viewModel.urlString.contains("blank"), let validURL = URL(string: viewModel.processUrlString()) {
                print("Loading URL: \(validURL)")
                if let coordinator = webView.navigationDelegate as? WebView.Coordinator {
                    coordinator.shouldLoadURL = true
                    webView.load(URLRequest(url: validURL))
                }
            }
        } else {
            viewModel.isBlocked = true
            viewModel.showAnimation = false
        }
    }
    
    
    private func goBack() {
        startAnimation()
        if webView.canGoBack { webView.goBack() }
    }
    
    private func goForward() {
        startAnimation()
        if webView.canGoForward { webView.goForward() }
    }
    
    private func reloadPage() {
        startAnimation()
        webView.reload()
    }
    
    private func startAnimation() {
        viewModel.showAnimation = true
        viewModel.animationProgress = 0.0
        withAnimation { viewModel.animationProgress = 1.0 }
    }
    
    private func updateURL(newURL: String) {
        if newURL == "loadingFinished" {
            viewModel.showAnimation = false
        }
    }
}

extension View {
    func placeholder<Content: View>(when shouldShow: Bool, alignment: Alignment = .leading, @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow { placeholder() }
            self
        }
    }
}
