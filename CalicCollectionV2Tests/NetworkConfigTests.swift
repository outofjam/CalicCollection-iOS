//
//  NetworkConfigTests.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-27.
//


import XCTest
@testable import CalicCollectionV2

@MainActor
final class NetworkConfigTests: XCTestCase {
    
    // MARK: - Configuration Tests
    
    func testTimeoutConfiguration() {
        XCTAssertEqual(NetworkConfig.requestTimeout, 30)
        XCTAssertEqual(NetworkConfig.resourceTimeout, 60)
    }
    
    func testRetryConfiguration() {
        XCTAssertEqual(NetworkConfig.maxRetries, 3)
        XCTAssertEqual(NetworkConfig.retryDelay, 1.0)
        XCTAssertEqual(NetworkConfig.retryMultiplier, 2.0)
    }
    
    func testRetryableStatusCodes() {
        let expectedCodes: Set<Int> = [408, 429, 500, 502, 503, 504]
        XCTAssertEqual(NetworkConfig.retryableStatusCodes, expectedCodes)
    }
    
    func testSessionConfiguration() {
        let config = NetworkConfig.session.configuration
        
        XCTAssertEqual(config.timeoutIntervalForRequest, 30)
        XCTAssertEqual(config.timeoutIntervalForResource, 60)
        XCTAssertTrue(config.waitsForConnectivity)
        XCTAssertNil(config.urlCache)
    }
    
    // MARK: - Retry Logic Tests
    
    func testNonRetryableStatusCodeDoesNotRetry() async throws {
        // 404 should not trigger retry
        XCTAssertFalse(NetworkConfig.retryableStatusCodes.contains(404))
    }
    
    func testRetryableStatusCodesAreCorrect() {
        // These should all trigger retry
        XCTAssertTrue(NetworkConfig.retryableStatusCodes.contains(408)) // Request Timeout
        XCTAssertTrue(NetworkConfig.retryableStatusCodes.contains(429)) // Too Many Requests
        XCTAssertTrue(NetworkConfig.retryableStatusCodes.contains(500)) // Internal Server Error
        XCTAssertTrue(NetworkConfig.retryableStatusCodes.contains(502)) // Bad Gateway
        XCTAssertTrue(NetworkConfig.retryableStatusCodes.contains(503)) // Service Unavailable
        XCTAssertTrue(NetworkConfig.retryableStatusCodes.contains(504)) // Gateway Timeout
        
        // These should not trigger retry
        XCTAssertFalse(NetworkConfig.retryableStatusCodes.contains(200)) // OK
        XCTAssertFalse(NetworkConfig.retryableStatusCodes.contains(201)) // Created
        XCTAssertFalse(NetworkConfig.retryableStatusCodes.contains(400)) // Bad Request
        XCTAssertFalse(NetworkConfig.retryableStatusCodes.contains(401)) // Unauthorized
        XCTAssertFalse(NetworkConfig.retryableStatusCodes.contains(403)) // Forbidden
        XCTAssertFalse(NetworkConfig.retryableStatusCodes.contains(404)) // Not Found
        XCTAssertFalse(NetworkConfig.retryableStatusCodes.contains(422)) // Unprocessable Entity
    }
    
    func testExponentialBackoffCalculation() {
        let baseDelay = NetworkConfig.retryDelay
        let multiplier = NetworkConfig.retryMultiplier
        
        // First retry: 1s
        XCTAssertEqual(baseDelay, 1.0)
        
        // Second retry: 2s
        XCTAssertEqual(baseDelay * multiplier, 2.0)
        
        // Third retry: 4s
        XCTAssertEqual(baseDelay * multiplier * multiplier, 4.0)
    }
}
