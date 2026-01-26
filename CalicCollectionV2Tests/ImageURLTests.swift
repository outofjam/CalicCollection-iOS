//
//  ImageURLTests.swift
//  CaliCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-23.
//


import XCTest
@testable import CalicCollectionV2

final class ImageURLTests: XCTestCase {
    
    // MARK: - Test Thumbnail Fallback
    
    func testThumbnailURLFallbackToImageURL() {
        // Given - variant with no thumbnail
        let variant = CritterVariant(
            uuid: UUID().uuidString,
            critterId: UUID().uuidString,
            name: "Test Variant",
            imageURL: "https://example.com/image.jpg",
            thumbnailURL: nil
        )
        
        // When
        let displayURL = variant.thumbnailURL ?? variant.imageURL
        
        // Then
        XCTAssertEqual(displayURL, "https://example.com/image.jpg", "Should fallback to imageURL")
    }
    
    func testThumbnailURLPreferred() {
        // Given - variant with both URLs
        let variant = CritterVariant(
            uuid: UUID().uuidString,
            critterId: UUID().uuidString,
            name: "Test Variant",
            imageURL: "https://example.com/image.jpg",
            thumbnailURL: "https://example.com/thumb.jpg"
        )
        
        // When
        let displayURL = variant.thumbnailURL ?? variant.imageURL
        
        // Then
        XCTAssertEqual(displayURL, "https://example.com/thumb.jpg", "Should use thumbnail when available")
    }
    
    func testBothURLsNil() {
        // Given - variant with no images
        let variant = CritterVariant(
            uuid: UUID().uuidString,
            critterId: UUID().uuidString,
            name: "Test Variant",
            imageURL: nil,
            thumbnailURL: nil
        )
        
        // When
        let displayURL = variant.thumbnailURL ?? variant.imageURL
        
        // Then
        XCTAssertNil(displayURL, "Should be nil when both are nil")
    }
    
    // MARK: - Test OwnedVariant URLs
    
    func testOwnedVariantThumbnailFallback() {
        // Given
        let ownedVariant = OwnedVariant(
            variantUuid: UUID().uuidString,
            critterUuid: UUID().uuidString,
            critterName: "Test Critter",
            variantName: "Test Variant",
            familyId: UUID().uuidString,
            memberType: "Kids",
            imageURL: "https://example.com/image.jpg",
            thumbnailURL: nil,
            status: .collection
        )
        
        // When
        let displayURL = ownedVariant.thumbnailURL ?? ownedVariant.imageURL
        
        // Then
        XCTAssertEqual(displayURL, "https://example.com/image.jpg")
    }
    
    func testOwnedVariantPrefersThumbnail() {
        // Given
        let ownedVariant = OwnedVariant(
            variantUuid: UUID().uuidString,
            critterUuid: UUID().uuidString,
            critterName: "Test Critter",
            variantName: "Test Variant",
            familyId: UUID().uuidString,
            memberType: "Kids",
            imageURL: "https://example.com/image.jpg",
            thumbnailURL: "https://example.com/thumb.jpg",
            status: .collection
        )
        
        // When
        let displayURL = ownedVariant.thumbnailURL ?? ownedVariant.imageURL
        
        // Then
        XCTAssertEqual(displayURL, "https://example.com/thumb.jpg")
    }
}
