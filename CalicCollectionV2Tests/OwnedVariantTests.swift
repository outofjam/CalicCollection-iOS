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
    
    // MARK: - Test Creation from SearchResult
    
    func testCreateOwnedVariantFromSearchResult() async throws {
        // Given
        let searchResult = createTestSearchResult()
        
        // When
        try await OwnedVariant.create(
            from: searchResult,
            status: .wishlist,
            in: modelContext
        )
        
        // Then
        let descriptor = FetchDescriptor<OwnedVariant>()
        let ownedVariants = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(ownedVariants.count, 1)
        XCTAssertEqual(ownedVariants.first?.variantUuid, searchResult.variantUuid)
        XCTAssertEqual(ownedVariants.first?.status, .wishlist)
        XCTAssertEqual(ownedVariants.first?.critterName, searchResult.critterName)
        XCTAssertEqual(ownedVariants.first?.familyName, searchResult.familyName)
        XCTAssertEqual(ownedVariants.first?.familyId, searchResult.familyUuid)
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
            familyName: "Test Family",
            familyUuid: familyUuid
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
    
    // MARK: - Helper Methods
    
    private func createTestCritterInfo() -> CritterInfo {
        return CritterInfo(
            uuid: UUID().uuidString,
            name: "Test Husky",
            memberType: "Kids",
            familyName: "Husky Family",
            familyUuid: UUID().uuidString
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
    
    private func createTestSearchResult() -> SearchResultResponse {
        return SearchResultResponse(
            variantUuid: UUID().uuidString,
            variantName: "Search Result Variant",
            critterUuid: UUID().uuidString,
            critterName: "Search Critter",
            familyUuid: UUID().uuidString,
            familyName: "Search Family",
            memberType: "Parents",
            imageUrl: "https://example.com/search-image.jpg",
            thumbnailUrl: "https://example.com/search-thumb.jpg",
            setName: nil,
            releaseYear: 2023
        )
    }
}
