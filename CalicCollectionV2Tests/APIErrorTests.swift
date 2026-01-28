//
//  APIErrorTests.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-28.
//


//
//  APIErrorTests.swift
//  CalicCollectionV2Tests
//
//  Created by Ismail Dawoodjee on 2026-01-28.
//

import XCTest
@testable import CalicCollectionV2

final class APIErrorTests: XCTestCase {
    
    // MARK: - APIError Description Tests
    
    func testInvalidURLErrorDescription() {
        let error = APIError.invalidURL
        XCTAssertEqual(error.localizedDescription, "Invalid URL")
    }
    
    func testInvalidResponseErrorDescription() {
        let error = APIError.invalidResponse
        XCTAssertEqual(error.localizedDescription, "Invalid response from server")
    }
    
    func testNotFoundErrorDescription() {
        let error = APIError.notFound(message: "Critter not found")
        XCTAssertEqual(error.localizedDescription, "Critter not found")
    }
    
    func testHTTPErrorDescription() {
        let error400 = APIError.httpError(statusCode: 400)
        XCTAssertTrue(error400.localizedDescription.contains("400"))
        
        let error500 = APIError.httpError(statusCode: 500)
        XCTAssertTrue(error500.localizedDescription.contains("500"))
        
        let error404 = APIError.httpError(statusCode: 404)
        XCTAssertTrue(error404.localizedDescription.contains("404"))
    }
    
    func testRateLimitedErrorDescription() {
        let error = APIError.rateLimited
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }
    
    func testDecodingErrorDescription() {
        let error = APIError.decodingError(message: "Failed to decode response")
        XCTAssertEqual(error.localizedDescription, "Failed to decode response")
    }
    
    func testNetworkErrorDescription() {
        let underlyingError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."]
        )
        let error = APIError.networkError(underlyingError)
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }
    
    // MARK: - CritterStatus Tests
    
    func testCritterStatusRawValues() {
        XCTAssertEqual(CritterStatus.collection.rawValue, "collection")
        XCTAssertEqual(CritterStatus.wishlist.rawValue, "wishlist")
    }
    
    func testCritterStatusFromRawValue() {
        XCTAssertEqual(CritterStatus(rawValue: "collection"), .collection)
        XCTAssertEqual(CritterStatus(rawValue: "wishlist"), .wishlist)
        XCTAssertNil(CritterStatus(rawValue: "invalid"))
        XCTAssertNil(CritterStatus(rawValue: ""))
    }
    
    func testCritterStatusAllCases() {
        XCTAssertEqual(CritterStatus.allCases.count, 2)
        XCTAssertTrue(CritterStatus.allCases.contains(.collection))
        XCTAssertTrue(CritterStatus.allCases.contains(.wishlist))
    }
    
    // MARK: - ReportIssueType Tests
    
    func testReportIssueTypeRawValues() {
        XCTAssertEqual(ReportIssueType.incorrectImage.rawValue, "incorrect_image")
        XCTAssertEqual(ReportIssueType.incorrectName.rawValue, "incorrect_name")
        XCTAssertEqual(ReportIssueType.incorrectSet.rawValue, "incorrect_set")
        XCTAssertEqual(ReportIssueType.incorrectYear.rawValue, "incorrect_year")
        XCTAssertEqual(ReportIssueType.other.rawValue, "other")
    }
    
    func testReportIssueTypeDisplayNames() {
        XCTAssertEqual(ReportIssueType.incorrectImage.displayName, "Incorrect Image")
        XCTAssertEqual(ReportIssueType.incorrectName.displayName, "Incorrect Name")
        XCTAssertEqual(ReportIssueType.incorrectSet.displayName, "Incorrect Set")
        XCTAssertEqual(ReportIssueType.incorrectYear.displayName, "Incorrect Release Year")
        XCTAssertEqual(ReportIssueType.other.displayName, "Other Issue")
    }
    
    func testReportIssueTypeIcons() {
        XCTAssertEqual(ReportIssueType.incorrectImage.icon, "photo")
        XCTAssertEqual(ReportIssueType.incorrectName.icon, "textformat")
        XCTAssertEqual(ReportIssueType.incorrectSet.icon, "square.stack.3d.up")
        XCTAssertEqual(ReportIssueType.incorrectYear.icon, "calendar")
        XCTAssertEqual(ReportIssueType.other.icon, "exclamationmark.circle")
    }
    
    func testReportIssueTypeAllCases() {
        XCTAssertEqual(ReportIssueType.allCases.count, 5)
    }
    
    // MARK: - ReportRequest Encoding Tests
    
    func testReportRequestEncoding() throws {
        let request = ReportRequest(
            variantUuid: "variant-123",
            issueType: .incorrectImage,
            details: "The image shows wrong critter",
            suggestedCorrection: "Should be the baby version",
            deviceId: "device-456"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        XCTAssertEqual(json["variant_uuid"] as? String, "variant-123")
        XCTAssertEqual(json["issue_type"] as? String, "incorrect_image")
        XCTAssertEqual(json["details"] as? String, "The image shows wrong critter")
        XCTAssertEqual(json["suggested_correction"] as? String, "Should be the baby version")
        XCTAssertEqual(json["device_id"] as? String, "device-456")
    }
    
    func testReportRequestEncodingWithNils() throws {
        let request = ReportRequest(
            variantUuid: "variant-123",
            issueType: .other,
            details: nil,
            suggestedCorrection: nil,
            deviceId: "device-456"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let jsonString = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(jsonString.contains("variant_uuid"))
        XCTAssertTrue(jsonString.contains("issue_type"))
        XCTAssertTrue(jsonString.contains("device_id"))
    }
    
    func testReportRequestEncodesAllIssueTypes() throws {
        let encoder = JSONEncoder()
        
        for issueType in ReportIssueType.allCases {
            let request = ReportRequest(
                variantUuid: "test",
                issueType: issueType,
                details: nil,
                suggestedCorrection: nil,
                deviceId: "device"
            )
            
            let data = try encoder.encode(request)
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            
            XCTAssertEqual(json["issue_type"] as? String, issueType.rawValue)
        }
    }
}