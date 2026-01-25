import XCTest
import SwiftData
@testable import CalicCollectionV2

final class OwnedVariantTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        // Create in-memory container for testing
        let schema = Schema([
            Critter.self,
            CritterVariant.self,
            Family.self,
            OwnedVariant.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - Test Creation
    
    func testCreateOwnedVariant() throws {
        // Given
        let critter = createTestCritter()
        let variant = createTestVariant(critterId: critter.uuid)
        
        // When
        try OwnedVariant.create(
            variant: variant,
            critter: critter,
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
        XCTAssertEqual(ownedVariants.first?.imageURL, variant.imageURL)
        XCTAssertEqual(ownedVariants.first?.thumbnailURL, variant.thumbnailURL)
    }
    
    func testCreateDuplicateUpdatesStatus() throws {
        // Given
        let critter = createTestCritter()
        let variant = createTestVariant(critterId: critter.uuid)
        
        // Create as collection first
        try OwnedVariant.create(
            variant: variant,
            critter: critter,
            status: .collection,
            in: modelContext
        )
        
        // When - Add same variant as wishlist
        try OwnedVariant.create(
            variant: variant,
            critter: critter,
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
    
    func testRemoveOwnedVariant() throws {
        // Given
        let critter = createTestCritter()
        let variant = createTestVariant(critterId: critter.uuid)
        
        try OwnedVariant.create(
            variant: variant,
            critter: critter,
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
    
    func testCollectionToWishlistTransition() throws {
        // Given
        let critter = createTestCritter()
        let variant = createTestVariant(critterId: critter.uuid)
        
        try OwnedVariant.create(
            variant: variant,
            critter: critter,
            status: .collection,
            in: modelContext
        )
        
        // When - Move to wishlist
        try OwnedVariant.create(
            variant: variant,
            critter: critter,
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
    
    func testWishlistToCollectionTransition() throws {
        // Given
        let critter = createTestCritter()
        let variant = createTestVariant(critterId: critter.uuid)
        
        try OwnedVariant.create(
            variant: variant,
            critter: critter,
            status: .wishlist,
            in: modelContext
        )
        
        // When - Move to collection
        try OwnedVariant.create(
            variant: variant,
            critter: critter,
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
    
    // MARK: - Helper Methods
    
    private func createTestCritter() -> Critter {
        return Critter(
            uuid: UUID().uuidString,
            familyId: UUID().uuidString,
            name: "Test Husky",
            memberType: "Kids",
            role: "Sister",
            familyName: "Husky Dog",
            familySpecies: "Dog",
            variantsCount: 1
        )
    }
    
    private func createTestVariant(critterId: String) -> CritterVariant {
        return CritterVariant(
            uuid: UUID().uuidString,
            critterId: critterId,
            name: "Test Variant",
            sku: "TEST-001",
            imageURL: "https://example.com/image.jpg",
            thumbnailURL: "https://example.com/thumb.jpg"
        )
    }
}
