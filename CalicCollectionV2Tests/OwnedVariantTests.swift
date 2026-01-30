//
//  OwnedVariantTests.swift
//  CalicCollectionV2Tests
//
//  Created by Ismail Dawoodjee on 2026-01-28.
//

import XCTest
import SwiftData
@testable import CalicCollectionV2

final class OwnedVariantTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        // Create in-memory container for testing
        let schema = Schema([
            Family.self,
            OwnedVariant.self,
            VariantPhoto.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - Test Creation from VariantResponse
    
    func testCreateOwnedVariantFromVariantResponse() async throws {
        // Given
        let critter = createTestCritterInfo()
        let variant = createTestVariantResponse(critterId: critter.uuid)
        
        // When
        try await OwnedVariant.create(
            variant: variant,
            critter: critter,
            familyId: critter.familyUuid ?? "",
            status: .collection,
            in: modelContext
        )
        
        // Then
        let descriptor = FetchDescriptor<OwnedVariant>()
        let ownedVariants = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(ownedVariants.count, 1)
        XCTAssertEqual(ownedVariants.first?.variantUuid, variant.uuid)
        XCTAssertEqual(ownedVariants.first?.status, .collection)
        XCTAssertEqual(ownedVariants.first?.critterName, critter.name)
        XCTAssertEqual(ownedVariants.first?.familyName, critter.familyName)
        XCTAssertEqual(ownedVariants.first?.familyId, critter.familyUuid)
    }
    
    // MARK: - Test Direct Initialization
    
    func testCreateOwnedVariantDirectly() throws {
        // Given
        let variantUuid = UUID().uuidString
        let critterUuid = UUID().uuidString
        let familyId = UUID().uuidString
        
        // When
        let owned = OwnedVariant(
            variantUuid: variantUuid,
            critterUuid: critterUuid,
            critterName: "Flora Rabbit",
            variantName: "Holiday Edition",
            familyId: familyId,
            familyName: "Flora Rabbit Family",
            familySpecies: "Rabbit",
            memberType: "Babies",
            role: nil,
            epochId: "5735",
            setName: "Holiday Set 2024",
            imageURL: "https://example.com/image.jpg",
            thumbnailURL: "https://example.com/thumb.jpg",
            status: .wishlist
        )
        
        modelContext.insert(owned)
        try modelContext.save()
        
        // Then
        let descriptor = FetchDescriptor<OwnedVariant>()
        let ownedVariants = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(ownedVariants.count, 1)
        XCTAssertEqual(ownedVariants.first?.variantUuid, variantUuid)
        XCTAssertEqual(ownedVariants.first?.status, .wishlist)
        XCTAssertEqual(ownedVariants.first?.critterName, "Flora Rabbit")
        XCTAssertEqual(ownedVariants.first?.epochId, "5735")
        XCTAssertEqual(ownedVariants.first?.setName, "Holiday Set 2024")
    }
    
    // MARK: - Test Duplicate Handling
    
    func testCreateDuplicateUpdatesStatus() async throws {
        // Given
        let critter = createTestCritterInfo()
        let variant = createTestVariantResponse(critterId: critter.uuid)
        
        // Create as collection first
        try await OwnedVariant.create(
            variant: variant,
            critter: critter,
            familyId: critter.familyUuid ?? "",
            status: .collection,
            in: modelContext
        )
        
        // When - Add same variant as wishlist
        try await OwnedVariant.create(
            variant: variant,
            critter: critter,
            familyId: critter.familyUuid ?? "",
            status: .wishlist,
            in: modelContext
        )
        
        // Then - Should update, not create duplicate
        let descriptor = FetchDescriptor<OwnedVariant>()
        let ownedVariants = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(ownedVariants.count, 1, "Should not create duplicate")
        XCTAssertEqual(ownedVariants.first?.status, .wishlist, "Status should be updated")
    }
    
    // MARK: - Test Removal
    
    func testRemoveOwnedVariant() async throws {
        // Given
        let critter = createTestCritterInfo()
        let variant = createTestVariantResponse(critterId: critter.uuid)
        
        try await OwnedVariant.create(
            variant: variant,
            critter: critter,
            familyId: critter.familyUuid ?? "",
            status: .collection,
            in: modelContext
        )
        
        // When
        try OwnedVariant.remove(variantUuid: variant.uuid, in: modelContext)
        
        // Then
        let descriptor = FetchDescriptor<OwnedVariant>()
        let ownedVariants = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(ownedVariants.count, 0, "Variant should be removed")
    }
    
    func testRemoveNonExistentVariant() throws {
        // Given
        let nonExistentUuid = "non-existent-uuid"
        
        // When/Then - Should not crash
        XCTAssertNoThrow(
            try OwnedVariant.remove(variantUuid: nonExistentUuid, in: modelContext)
        )
    }
    
    // MARK: - Test Status Transitions
    
    func testCollectionToWishlistTransition() async throws {
        // Given
        let critter = createTestCritterInfo()
        let variant = createTestVariantResponse(critterId: critter.uuid)
        
        try await OwnedVariant.create(
            variant: variant,
            critter: critter,
            familyId: critter.familyUuid ?? "",
            status: .collection,
            in: modelContext
        )
        
        // When - Move to wishlist
        try await OwnedVariant.create(
            variant: variant,
            critter: critter,
            familyId: critter.familyUuid ?? "",
            status: .wishlist,
            in: modelContext
        )
        
        // Then
        let variantUuid = variant.uuid
        let descriptor = FetchDescriptor<OwnedVariant>(
            predicate: #Predicate { $0.variantUuid == variantUuid }
        )
        let ownedVariant = try modelContext.fetch(descriptor).first
        
        XCTAssertNotNil(ownedVariant)
        XCTAssertEqual(ownedVariant?.status, .wishlist)
    }
    
    func testWishlistToCollectionTransition() async throws {
        // Given
        let critter = createTestCritterInfo()
        let variant = createTestVariantResponse(critterId: critter.uuid)
        
        try await OwnedVariant.create(
            variant: variant,
            critter: critter,
            familyId: critter.familyUuid ?? "",
            status: .wishlist,
            in: modelContext
        )
        
        // When - Move to collection
        try await OwnedVariant.create(
            variant: variant,
            critter: critter,
            familyId: critter.familyUuid ?? "",
            status: .collection,
            in: modelContext
        )
        
        // Then
        let variantUuid = variant.uuid
        let descriptor = FetchDescriptor<OwnedVariant>(
            predicate: #Predicate { $0.variantUuid == variantUuid }
        )
        let ownedVariant = try modelContext.fetch(descriptor).first
        
        XCTAssertNotNil(ownedVariant)
        XCTAssertEqual(ownedVariant?.status, .collection)
    }
    
    // MARK: - Test Family ID Storage
    
    func testFamilyIdIsStoredCorrectly() async throws {
        // Given
        let familyUuid = UUID().uuidString
        let critter = CritterInfo(
            uuid: UUID().uuidString,
            name: "Test Critter",
            memberType: "Kids",
            birthday: nil,
            familyName: "Test Family",
            familyUuid: familyUuid,
            species: "fox"
            
        )
        let variant = createTestVariantResponse(critterId: critter.uuid)
        
        // When
        try await OwnedVariant.create(
            variant: variant,
            critter: critter,
            familyId: familyUuid,
            status: .collection,
            in: modelContext
        )
        
        // Then
        let descriptor = FetchDescriptor<OwnedVariant>()
        let ownedVariant = try modelContext.fetch(descriptor).first
        
        XCTAssertEqual(ownedVariant?.familyId, familyUuid)
        XCTAssertFalse(ownedVariant?.familyId.isEmpty ?? true, "Family ID should not be empty")
    }
    
    // MARK: - Test Status Computed Property
    
    func testStatusComputedProperty() throws {
        // Given
        let owned = OwnedVariant(
            variantUuid: UUID().uuidString,
            critterUuid: UUID().uuidString,
            critterName: "Test",
            variantName: "Test Variant",
            familyId: UUID().uuidString,
            memberType: "Kids",
            status: .collection
        )
        
        // Then
        XCTAssertEqual(owned.status, .collection)
        XCTAssertEqual(owned.statusRaw, "collection")
        
        // When - Change status
        owned.status = .wishlist
        
        // Then
        XCTAssertEqual(owned.status, .wishlist)
        XCTAssertEqual(owned.statusRaw, "wishlist")
    }
    
    // MARK: - Test hasLocalImages Computed Property
    
    func testHasLocalImagesWithNoImages() throws {
        // Given
        let owned = OwnedVariant(
            variantUuid: UUID().uuidString,
            critterUuid: UUID().uuidString,
            critterName: "Test",
            variantName: "Test Variant",
            familyId: UUID().uuidString,
            memberType: "Kids",
            localImagePath: nil,
            localThumbnailPath: nil,
            status: .collection
        )
        
        // Then
        XCTAssertFalse(owned.hasLocalImages)
    }
    
    func testHasLocalImagesWithThumbnail() throws {
        // Given
        let owned = OwnedVariant(
            variantUuid: UUID().uuidString,
            critterUuid: UUID().uuidString,
            critterName: "Test",
            variantName: "Test Variant",
            familyId: UUID().uuidString,
            memberType: "Kids",
            localImagePath: nil,
            localThumbnailPath: "/path/to/thumb.jpg",
            status: .collection
        )
        
        // Then
        XCTAssertTrue(owned.hasLocalImages)
    }
    
    func testHasLocalImagesWithFullImage() throws {
        // Given
        let owned = OwnedVariant(
            variantUuid: UUID().uuidString,
            critterUuid: UUID().uuidString,
            critterName: "Test",
            variantName: "Test Variant",
            familyId: UUID().uuidString,
            memberType: "Kids",
            localImagePath: "/path/to/image.jpg",
            localThumbnailPath: nil,
            status: .collection
        )
        
        // Then
        XCTAssertTrue(owned.hasLocalImages)
    }
    
    // MARK: - Test Epoch/Set Info Storage
    
    func testEpochAndSetInfoIsStored() async throws {
        // Given
        let critter = createTestCritterInfo()
        let variant = VariantResponse(
            uuid: UUID().uuidString,
            critterId: critter.uuid,
            name: "Holiday Edition",
            sku: "CC-5735-01",
            barcode: nil,
            imageUrl: nil,
            thumbnailUrl: nil,
            releaseYear: 2024,
            notes: nil,
            setId: "set-123",
            setName: "Holiday Set 2024",
            epochId: "5735",
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z",
            isPrimary: true
        )
        
        // When
        try await OwnedVariant.create(
            variant: variant,
            critter: critter,
            familyId: critter.familyUuid ?? "",
            status: .collection,
            in: modelContext
        )
        
        // Then
        let descriptor = FetchDescriptor<OwnedVariant>()
        let ownedVariant = try modelContext.fetch(descriptor).first
        
        XCTAssertEqual(ownedVariant?.epochId, "5735")
        XCTAssertEqual(ownedVariant?.setName, "Holiday Set 2024")
    }
    
    // MARK: - Helper Methods
    
    private func createTestCritterInfo() -> CritterInfo {
        return CritterInfo(
            uuid: UUID().uuidString,
            name: "Test Husky",
            memberType: "Kids",
            birthday: "03-15",
            familyName: "Husky Family",
            familyUuid: UUID().uuidString,
            species: "fox"
        )
    }
    
    private func createTestVariantResponse(critterId: String) -> VariantResponse {
        return VariantResponse(
            uuid: UUID().uuidString,
            critterId: critterId,
            name: "Test Variant",
            sku: "TEST-001",
            barcode: nil,
            imageUrl: "https://example.com/image.jpg",
            thumbnailUrl: "https://example.com/thumb.jpg",
            releaseYear: 2024,
            notes: nil,
            setId: nil,
            setName: nil,
            epochId: nil,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z",
            isPrimary: true
        )
    }
}
