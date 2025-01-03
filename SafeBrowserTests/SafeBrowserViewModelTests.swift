//
//  SafeBrowserViewModelTests.swift
//  SafeBrowserTests
//
//  Created by Md Faizul karim on 3/1/25.
//

import XCTest
import Combine
@testable import SafeBrowser

class MockDNSResolver: DNSResolverProtocol {
    var resolveResult: String = "not found"

    func resolve(domain: String) -> AnyPublisher<String, Never> {
        Just(resolveResult).eraseToAnyPublisher()
    }
}

final class SafeBrowserViewModelTests: XCTestCase {
    private var viewModel: SafeBrowserViewModel!
    private var mockResolver: MockDNSResolver!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockResolver = MockDNSResolver()
        viewModel = SafeBrowserViewModel(dnsResolver: mockResolver)
        cancellables = []
    }

    override func tearDown() {
        viewModel = nil
        mockResolver = nil
        cancellables = nil
        super.tearDown()
    }

    func testCheckURL_withSafeDomain_setsIsBlockedFalse() {
        // Arrange
        mockResolver.resolveResult = "not found"
        viewModel.urlString = "https://www.google.com"

        // Act
        let expectation = self.expectation(description: "DNS resolution for safe domain")
        viewModel.$isBlocked
            .dropFirst() // Skip initial value
            .sink { isBlocked in
                // Assert
                XCTAssertFalse(isBlocked)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.checkURL()
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCheckURL_withBlockedDomain_setsIsBlockedTrue() {
        // Arrange
        mockResolver.resolveResult = "1.1.1.1"
        viewModel.urlString = "https://www.haram.com"

        // Act
        let expectation = self.expectation(description: "DNS resolution for blocked domain")
        viewModel.$isBlocked
            .dropFirst() // Skip initial value
            .sink { isBlocked in
                // Assert
                XCTAssertTrue(isBlocked)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.checkURL()
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testProcessUrlString_withMissingScheme_addsHTTPS() {
        // Arrange
        viewModel.urlString = "example.com"

        // Act
        let processedURL = viewModel.processUrlString()

        // Assert
        XCTAssertEqual(processedURL, "https://example.com")
    }

    func testProcessUrlString_withScheme_doesNotChangeURL() {
        // Arrange
        viewModel.urlString = "http://example.com"

        // Act
        let processedURL = viewModel.processUrlString()

        // Assert
        XCTAssertEqual(processedURL, "http://example.com")
    }

    func testExtractDomain_withValidURL_returnsDomain() {
        // Arrange
        let url = "https://example.com/path"

        // Act
        let domain = viewModel.extractDomain(from: url)

        // Assert
        XCTAssertEqual(domain, "https://example.com")
    }

    func testExtractDomain_withInvalidURL_returnsNil() {
        // Arrange
        let url = "invalid-url"

        // Act
        let domain = viewModel.extractDomain(from: url)

        // Assert
        XCTAssertNil(domain)
    }

    func testCheckURL_setsShowAnimationToFalseAfterResolution() {
        // Arrange
        mockResolver.resolveResult = "1.1.1.1"
        viewModel.urlString = "https://blocked.com"

        // Act
        let expectation = self.expectation(description: "ShowAnimation set to false")
        viewModel.$showAnimation
            .dropFirst() // Skip initial value
            .sink { showAnimation in
                if !showAnimation {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.checkURL()
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
