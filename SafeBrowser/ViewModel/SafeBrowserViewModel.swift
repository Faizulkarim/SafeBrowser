//
//  SafeBrowserModel.swift
//  SafeBrowser
//
//  Created by Md Faizul karim on 31/12/24.
//

import Combine
import SwiftUI
import WebKit

// MARK: - SafeBrowserViewModel

class SafeBrowserViewModel: ObservableObject {
    @Published var dnsAnswer: String = ""
    @Published var urlString: String = ""
    @Published var isBlocked = false
    @Published var showAnimation = false
    @Published var animationProgress: CGFloat = 0.0
    @Published var canGoBack = false
    @Published var canGoForward = false
    private let dnsResolver: DNSResolverProtocol
    private var cancellables: Set<AnyCancellable> = []
    
    init(dnsResolver: DNSResolverProtocol = DNSResolver()) {
        self.dnsResolver = dnsResolver
    }
    
    func checkURL() {
        guard let domain = extractDomain(from: processUrlString()) else { return }
        showAnimation = true
        animationProgress = 0.0
        withAnimation { animationProgress = 1.0 }
        
        dnsResolver.resolve(domain: domain)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] answer in
                guard let self = self else { return }
                self.dnsAnswer = answer
                self.urlString = processUrlString()
                if answer == "not found" {
                    self.isBlocked = false
                } else {
                    self.isBlocked = true
                }
                self.showAnimation = false
            }
            .store(in: &cancellables)
    }
    
    func processUrlString() -> String {
        var processedURLString = urlString
        if !processedURLString.hasPrefix("http://") && !processedURLString.hasPrefix("https://") {
            processedURLString = "https://" + urlString
        }
        return processedURLString
    }
    
    func extractDomain(from urlString: String) -> String? {
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              let host = url.host else { return nil }
        return "\(scheme)://\(host)"
    }
    
}


