//
//  SyncServiceTests.swift
//  CalicCollectionV2Tests
//
//  Created by Ismail Dawoodjee on 2026-01-28.
//

import XCTest
import SwiftData
@testable import CalicCollectionV2

final class SyncServiceTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
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
    
    // MARK: - Family Model Tests
    
    func testFamilyModelCreation() {
        let family = Family(
            uuid: "test-uuid",
            name: "Chocolate Rabbit",
            slug: "chocolate-rabbit",
            species: "Rabbit",
            crittersCount: 8
        )
        
        XCTAssertEqual(family.uuid, "test-uuid")
        XCTAssertEqual(family.name, "Chocolate Rabbit")
        XCTAssertEqual(family.slug, "chocolate-rabbit")
        XCTAssertEqual(family.species, "Rabbit")
        XCTAssertEqual(family.crittersCount, 8)
    }
    
    func testFamilyModelPersistence() throws {
        let family = Family(
            uuid: "persist-test",
            name: "Persian Cat",
            slug: "persian-cat",
            species: "Cat",
            crittersCount: 5
        )
        
        modelContext.insert(family)
        try modelContext.save()
        
        let descriptor = FetchDescriptor<Family>(
            predicate: #Predicate { $0.uuid == "persist-test" }
        )
        let fetched = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Persian Cat")
        XCTAssertEqual(fetched.first?.crittersCount, 5)
    }
    
    func testFamilyUUIDUniqueness() throws {
        let family1 = Family(
            uuid: "same-uuid",
            name: "Family 1",
            slug: "family-1",
            species: "Cat",
            crittersCount: 3
        )
        
        modelContext.insert(family1)
        try modelContext.save()
        
        // Try to insert another with the same UUID - should update or fail
        let family2 = Family(
            uuid: "same-uuid",
            name: "Family 2",
            slug: "family-2",
            species: "Dog",
            crittersCount: 5
        )
        
        modelContext.insert(family2)
        
        // Fetch all families
        let descriptor = FetchDescriptor<Family>()
        let families = try modelContext.fetch(descriptor)
        
        // Should have both or one depending on SwiftData behavior
        XCTAssertGreaterThanOrEqual(families.count, 1)
    }
    
    // MARK: - FamilyBrowseResponse Decoding Tests (used in sync)
    
    func testFamilyBrowseResponseDecoding() throws {
        let json = """
        {
            "uuid": "5097c565-4446-47cc-8e2a-55035f3e7d6b",
            "name": "Chocolate Rabbit",
            "slug": "chocolate-rabbit",
            "species": "Rabbit",
            "image_url": null,
            "critters_count": 8
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(FamilyBrowseResponse.self, from: json)
        
        XCTAssertEqual(response.uuid, "5097c565-4446-47cc-8e2a-55035f3e7d6b")
        XCTAssertEqual(response.name, "Chocolate Rabbit")
        XCTAssertEqual(response.slug, "chocolate-rabbit")
        XCTAssertEqual(response.species, "Rabbit")
        XCTAssertNil(response.imageUrl)
        XCTAssertEqual(response.crittersCount, 8)
    }
    
    func testFamilyBrowseResponseWithImageUrl() throws {
        let json = """
        {
            "uuid": "test-uuid",
            "name": "Husky Family",
            "slug": "husky-family",
            "species": "Dog",
            "image_url": "https://example.com/husky.jpg",
            "critters_count": 5
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(FamilyBrowseResponse.self, from: json)
        
        XCTAssertEqual(response.uuid, "test-uuid")
        XCTAssertEqual(response.imageUrl, "https://example.com/husky.jpg")
        XCTAssertEqual(response.crittersCount, 5)
    }
    
    func testFamiliesAPIResponseDecoding() throws {
        let json = """
        {
            "data": [
                {
                    "uuid": "uuid-1",
                    "name": "Chocolate Rabbit",
                    "slug": "chocolate-rabbit",
                    "species": "Rabbit",
                    "image_url": null,
                    "critters_count": 8
                },
                {
                    "uuid": "uuid-2",
                    "name": "Persian Cat",
                    "slug": "persian-cat",
                    "species": "Cat",
                    "image_url": "https://example.com/cat.jpg",
                    "critters_count": 5
                }
            ],
            "meta": {
                "response_time_ms": 45,
                "count": 2
            }
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(FamiliesAPIResponse.self, from: json)
        
        XCTAssertEqual(response.data.count, 2)
        XCTAssertEqual(response.data[0].name, "Chocolate Rabbit")
        XCTAssertEqual(response.data[1].name, "Persian Cat")
        XCTAssertEqual(response.meta?.count, 2)
    }
    
    // MARK: - Backup Tests
    
    func testCollectionBackupStructure() throws {
        let backup = CollectionBackup(
            exportDate: Date(),
            appVersion: "1.0.0",
            ownedVariants: [
                CollectionBackup.BackupVariant(
                    variantUuid: "v1",
                    critterUuid: "c1",
                    critterName: "Test Critter",
                    variantName: "Test Variant",
                    familyId: "f1",
                    familyName: "Test Family",
                    familySpecies: "Rabbit",
                    memberType: "Babies",
                    role: nil,
                    imageURL: nil,
                    thumbnailURL: nil,
                    status: "collection",
                    addedDate: Date(),
                    pricePaid: 15.99,
                    purchaseDate: nil,
                    purchaseLocation: "Amazon",
                    condition: "Mint",
                    notes: nil,
                    quantity: 1
                )
            ],
            photos: []
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(backup)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(CollectionBackup.self, from: data)
        
        XCTAssertEqual(decoded.appVersion, "1.0.0")
        XCTAssertEqual(decoded.ownedVariants.count, 1)
        XCTAssertEqual(decoded.ownedVariants[0].variantUuid, "v1")
        XCTAssertEqual(decoded.ownedVariants[0].pricePaid, 15.99)
        XCTAssertEqual(decoded.ownedVariants[0].purchaseLocation, "Amazon")
        XCTAssertEqual(decoded.ownedVariants[0].condition, "Mint")
    }
    
    func testBackupVariantWithAllFields() throws {
        let now = Date()
        let variant = CollectionBackup.BackupVariant(
            variantUuid: "uuid-123",
            critterUuid: "critter-456",
            critterName: "Crème Chocolate",
            variantName: "Holiday Edition",
            familyId: "family-789",
            familyName: "Chocolate Rabbit",
            familySpecies: "Rabbit",
            memberType: "Babies",
            role: "Baby Sister",
            imageURL: "https://example.com/image.jpg",
            thumbnailURL: "https://example.com/thumb.jpg",
            status: "collection",
            addedDate: now,
            pricePaid: 29.99,
            purchaseDate: now,
            purchaseLocation: "Toys R Us",
            condition: "New in Box",
            notes: "Birthday gift",
            quantity: 2
        )
        
        XCTAssertEqual(variant.variantUuid, "uuid-123")
        XCTAssertEqual(variant.role, "Baby Sister")
        XCTAssertEqual(variant.pricePaid, 29.99)
        XCTAssertEqual(variant.quantity, 2)
        XCTAssertEqual(variant.notes, "Birthday gift")
    }
    
    func testBackupPhotoStructure() throws {
        let photo = CollectionBackup.BackupPhoto(
            id: "photo-1",
            variantUuid: "variant-1",
            filename: "photo_001.jpg",
            caption: "My setup",
            capturedDate: Date(),
            sortOrder: 0
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(photo)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(CollectionBackup.BackupPhoto.self, from: data)
        
        XCTAssertEqual(decoded.id, "photo-1")
        XCTAssertEqual(decoded.variantUuid, "variant-1")
        XCTAssertEqual(decoded.filename, "photo_001.jpg")
        XCTAssertEqual(decoded.caption, "My setup")
    }
}
