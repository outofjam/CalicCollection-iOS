//
//  ImageURLTests.swift
//  CaliCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-23.
//
import XCTest
@testable import CalicCollectionV2

final class ImageURLTests: XCTestCase {
    
    // MARK: - Test VariantResponse URL Fallback
    
    func testVariantResponseThumbnailFallbackToImageURL() {
        // Given - variant with no thumbnail
        let variant = VariantResponse(
            uuid: UUID().uuidString,
            critterId: UUID().uuidString,
            name: "Test Variant",
            sku: nil,
            barcode: nil,
            imageUrl: "https://example.com/image.jpg",
            thumbnailUrl: nil,
            releaseYear: nil,
            notes: nil,
            setId: nil,
            setName: nil,
            epochId: nil,
            createdAt: "",
            updatedAt: "",
            isPrimary: false
        )
        
        // When
        let displayURL = variant.thumbnailUrl ?? variant.imageUrl
        
        // Then
        XCTAssertEqual(displayURL, "https://example.com/image.jpg", "Should fallback to imageUrl")
    }
    
    func testVariantResponseThumbnailPreferred() {
        // Given - variant with both URLs
        let variant = VariantResponse(
            uuid: UUID().uuidString,
            critterId: UUID().uuidString,
            name: "Test Variant",
            sku: nil,
            barcode: nil,
            imageUrl: "https://example.com/image.jpg",
            thumbnailUrl: "https://example.com/thumb.jpg",
            releaseYear: nil,
            notes: nil,
            setId: nil,
            setName: nil,
            epochId: nil,
            createdAt: "",
            updatedAt: "",
            isPrimary: false
        )
        
        // When
        let displayURL = variant.thumbnailUrl ?? variant.imageUrl
        
        // Then
        XCTAssertEqual(displayURL, "https://example.com/thumb.jpg", "Should use thumbnail when available")
    }
    
    func testVariantResponseBothURLsNil() {
        // Given - variant with no images
        let variant = VariantResponse(
            uuid: UUID().uuidString,
            critterId: UUID().uuidString,
            name: "Test Variant",
            sku: nil,
            barcode: nil,
            imageUrl: nil,
            thumbnailUrl: nil,
            releaseYear: nil,
            notes: nil,
            setId: nil,
            setName: nil,
            epochId: nil,
            createdAt: "",
            updatedAt: "",
            isPrimary: false
        )
        
        // When
        let displayURL = variant.thumbnailUrl ?? variant.imageUrl
        
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
    
    // MARK: - Test SearchResultResponse URLs
    
    func testSearchResultThumbnailFallback() {
        // Given
        let searchResult = SearchResultResponse(
            variantUuid: UUID().uuidString,
            variantName: "Test Variant",
            critterUuid: UUID().uuidString,
            critterName: "Test Critter",
            familyUuid: UUID().uuidString,
            familyName: "Test Family",
            memberType: "Kids",
            imageUrl: "https://example.com/image.jpg",
            thumbnailUrl: nil,
            setName: nil,
            releaseYear: nil
        )
        
        // When
        let displayURL = searchResult.thumbnailUrl ?? searchResult.imageUrl
        
        // Then
        XCTAssertEqual(displayURL, "https://example.com/image.jpg")
    }
    
    func testSearchResultPrefersThumbnail() {
        // Given
        let searchResult = SearchResultResponse(
            variantUuid: UUID().uuidString,
            variantName: "Test Variant",
            critterUuid: UUID().uuidString,
            critterName: "Test Critter",
            familyUuid: UUID().uuidString,
            familyName: "Test Family",
            memberType: "Kids",
            imageUrl: "https://example.com/image.jpg",
            thumbnailUrl: "https://example.com/thumb.jpg",
            setName: nil,
            releaseYear: nil
        )
        
        // When
        let displayURL = searchResult.thumbnailUrl ?? searchResult.imageUrl
        
        // Then
        XCTAssertEqual(displayURL, "https://example.com/thumb.jpg")
    }
}
