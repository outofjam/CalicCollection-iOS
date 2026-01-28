//
//  APIDecodingTests.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-28.
//


//
//  APIDecodingTests.swift
//  CalicCollectionV2Tests
//
//  Created by Ismail Dawoodjee on 2026-01-28.
//

import XCTest
@testable import CalicCollectionV2

final class APIDecodingTests: XCTestCase {
    
    var decoder: JSONDecoder!
    
    override func setUp() {
        super.setUp()
        decoder = JSONDecoder()
    }
    
    // MARK: - BrowseCritterResponse Tests
    
    func testDecodeBrowseCritterResponse() throws {
        let json = """
        {
            "uuid": "596327d4-220d-417d-94e3-1d3104f34045",
            "name": "Adelaide Outback",
            "member_type": "Babies",
            "family_uuid": "023ce04d-6a3f-4995-b140-b3467a20c456",
            "family_name": "Koala",
            "variants_count": 3,
            "thumbnail_url": "https://example.com/thumb.jpg"
        }
        """.data(using: .utf8)!
        
        let critter = try decoder.decode(BrowseCritterResponse.self, from: json)
        
        XCTAssertEqual(critter.uuid, "596327d4-220d-417d-94e3-1d3104f34045")
        XCTAssertEqual(critter.name, "Adelaide Outback")
        XCTAssertEqual(critter.memberType, "Babies")
        XCTAssertEqual(critter.familyUuid, "023ce04d-6a3f-4995-b140-b3467a20c456")
        XCTAssertEqual(critter.familyName, "Koala")
        XCTAssertEqual(critter.variantsCount, 3)
        XCTAssertEqual(critter.thumbnailUrl, "https://example.com/thumb.jpg")
    }
    
    func testDecodeBrowseCritterResponseWithNulls() throws {
        let json = """
        {
            "uuid": "test-uuid",
            "name": "Test Critter",
            "member_type": "Kids",
            "family_uuid": null,
            "family_name": null,
            "variants_count": 0,
            "thumbnail_url": null
        }
        """.data(using: .utf8)!
        
        let critter = try decoder.decode(BrowseCritterResponse.self, from: json)
        
        XCTAssertEqual(critter.uuid, "test-uuid")
        XCTAssertNil(critter.familyUuid)
        XCTAssertNil(critter.familyName)
        XCTAssertNil(critter.thumbnailUrl)
    }
    
    // MARK: - BrowseCrittersAPIResponse Tests
    
    func testDecodeBrowseCrittersAPIResponse() throws {
        let json = """
        {
            "data": [
                {
                    "uuid": "uuid-1",
                    "name": "Critter 1",
                    "member_type": "Babies",
                    "family_uuid": "family-1",
                    "family_name": "Test Family",
                    "variants_count": 2,
                    "thumbnail_url": null
                },
                {
                    "uuid": "uuid-2",
                    "name": "Critter 2",
                    "member_type": "Parents",
                    "family_uuid": "family-1",
                    "family_name": "Test Family",
                    "variants_count": 5,
                    "thumbnail_url": "https://example.com/thumb2.jpg"
                }
            ],
            "meta": {
                "current_page": 1,
                "last_page": 3,
                "per_page": 30,
                "total": 75,
                "response_time_ms": 64
            }
        }
        """.data(using: .utf8)!
        
        let response = try decoder.decode(BrowseCrittersAPIResponse.self, from: json)
        
        XCTAssertEqual(response.data.count, 2)
        XCTAssertEqual(response.data[0].name, "Critter 1")
        XCTAssertEqual(response.data[1].name, "Critter 2")
        XCTAssertEqual(response.meta.currentPage, 1)
        XCTAssertEqual(response.meta.lastPage, 3)
        XCTAssertEqual(response.meta.total, 75)
    }
    
    // MARK: - CritterVariantsResponse Tests
    
    func testDecodeCritterVariantsResponse() throws {
        let json = """
        {
            "data": {
                "critter": {
                    "uuid": "596327d4-220d-417d-94e3-1d3104f34045",
                    "name": "Adelaide Outback",
                    "member_type": "Babies",
                    "family_name": "Koala",
                    "family_uuid": "023ce04d-6a3f-4995-b140-b3467a20c456"
                },
                "variants": [
                    {
                        "uuid": "019bf052-0085-71df-aa04-433d64b47d5b",
                        "critter_id": "596327d4-220d-417d-94e3-1d3104f34045",
                        "name": "Adelaide Outback",
                        "sku": null,
                        "set_id": null,
                        "set_name": null,
                        "epoch_id": null,
                        "barcode": null,
                        "image_url": "https://example.com/image.webp",
                        "thumbnail_url": "https://example.com/thumb.webp",
                        "release_year": null,
                        "notes": null,
                        "is_primary": false,
                        "created_at": "2026-01-24T14:04:24.000000Z",
                        "updated_at": "2026-01-24T14:04:24.000000Z"
                    }
                ]
            },
            "meta": {
                "response_time_ms": 64,
                "count": 1
            }
        }
        """.data(using: .utf8)!
        
        let response = try decoder.decode(CritterVariantsAPIResponse.self, from: json)
        
        XCTAssertEqual(response.data.critter.uuid, "596327d4-220d-417d-94e3-1d3104f34045")
        XCTAssertEqual(response.data.critter.name, "Adelaide Outback")
        XCTAssertEqual(response.data.critter.familyUuid, "023ce04d-6a3f-4995-b140-b3467a20c456")
        XCTAssertEqual(response.data.variants.count, 1)
        XCTAssertEqual(response.data.variants[0].imageUrl, "https://example.com/image.webp")
    }
    
    // MARK: - SearchResultResponse Tests
    
    func testDecodeSearchResultResponse() throws {
        let json = """
        {
            "variant_uuid": "variant-123",
            "variant_name": "Holiday Edition",
            "critter_uuid": "critter-456",
            "critter_name": "Stella Chocolate",
            "family_uuid": "family-789",
            "family_name": "Chocolate Rabbit",
            "member_type": "Kids",
            "image_url": "https://example.com/image.jpg",
            "thumbnail_url": "https://example.com/thumb.jpg",
            "set_name": "Holiday Set",
            "release_year": 2023
        }
        """.data(using: .utf8)!
        
        let result = try decoder.decode(SearchResultResponse.self, from: json)
        
        XCTAssertEqual(result.variantUuid, "variant-123")
        XCTAssertEqual(result.variantName, "Holiday Edition")
        XCTAssertEqual(result.critterUuid, "critter-456")
        XCTAssertEqual(result.critterName, "Stella Chocolate")
        XCTAssertEqual(result.familyUuid, "family-789")
        XCTAssertEqual(result.familyName, "Chocolate Rabbit")
        XCTAssertEqual(result.memberType, "Kids")
        XCTAssertEqual(result.setName, "Holiday Set")
        XCTAssertEqual(result.releaseYear, 2023)
    }
    
    func testDecodeSearchResultResponseWithNulls() throws {
        let json = """
        {
            "variant_uuid": "variant-123",
            "variant_name": "Basic Variant",
            "critter_uuid": null,
            "critter_name": null,
            "family_uuid": null,
            "family_name": null,
            "member_type": null,
            "image_url": null,
            "thumbnail_url": null,
            "set_name": null,
            "release_year": null
        }
        """.data(using: .utf8)!
        
        let result = try decoder.decode(SearchResultResponse.self, from: json)
        
        XCTAssertEqual(result.variantUuid, "variant-123")
        XCTAssertEqual(result.variantName, "Basic Variant")
        XCTAssertNil(result.critterUuid)
        XCTAssertNil(result.critterName)
        XCTAssertNil(result.familyUuid)
        XCTAssertNil(result.releaseYear)
    }
    
    // MARK: - FamilyDetailResponse Tests
    
    func testDecodeFamilyDetailResponse() throws {
        let json = """
        {
            "data": {
                "uuid": "5097c565-4446-47cc-8e2a-55035f3e7d6b",
                "name": "Chocolate Rabbit",
                "slug": "chocolate-rabbit",
                "species": "Rabbit",
                "description": null,
                "image_url": null,
                "critters": [
                    {
                        "uuid": "e16cdb57-6cb1-4907-b4a5-0a3cad81e827",
                        "name": "Crème Chocolate",
                        "member_type": "Babies",
                        "variants_count": 51,
                        "thumbnail_url": "https://example.com/thumb.webp"
                    },
                    {
                        "uuid": "942380c8-8092-464b-bcf7-7702714a76ba",
                        "name": "Frasier Chocolate",
                        "member_type": "Parents",
                        "variants_count": 15,
                        "thumbnail_url": null
                    }
                ]
            },
            "meta": {
                "response_time_ms": 73,
                "count": 2
            }
        }
        """.data(using: .utf8)!
        
        let response = try decoder.decode(FamilyDetailAPIResponse.self, from: json)
        
        XCTAssertEqual(response.data.uuid, "5097c565-4446-47cc-8e2a-55035f3e7d6b")
        XCTAssertEqual(response.data.name, "Chocolate Rabbit")
        XCTAssertEqual(response.data.species, "Rabbit")
        XCTAssertNil(response.data.description)
        XCTAssertEqual(response.data.critters.count, 2)
        XCTAssertEqual(response.data.critters[0].name, "Crème Chocolate")
        XCTAssertEqual(response.data.critters[0].variantsCount, 51)
        XCTAssertEqual(response.data.critters[1].memberType, "Parents")
    }
    
    // MARK: - VariantResponse Tests
    
    func testDecodeVariantResponse() throws {
        let json = """
        {
            "uuid": "019bf052-0085-71df-aa04-433d64b47d5b",
            "critter_id": "596327d4-220d-417d-94e3-1d3104f34045",
            "name": "Holiday Special Edition",
            "sku": "CC-5735-01",
            "barcode": "5054131057353",
            "image_url": "https://example.com/image.webp",
            "thumbnail_url": "https://example.com/thumb.webp",
            "release_year": 2023,
            "notes": "Limited edition release",
            "set_id": "set-123",
            "set_name": "Holiday Set 2023",
            "epoch_id": "5735",
            "created_at": "2026-01-24T14:04:24.000000Z",
            "updated_at": "2026-01-24T14:04:24.000000Z",
            "is_primary": true
        }
        """.data(using: .utf8)!
        
        let variant = try decoder.decode(VariantResponse.self, from: json)
        
        XCTAssertEqual(variant.uuid, "019bf052-0085-71df-aa04-433d64b47d5b")
        XCTAssertEqual(variant.critterId, "596327d4-220d-417d-94e3-1d3104f34045")
        XCTAssertEqual(variant.name, "Holiday Special Edition")
        XCTAssertEqual(variant.sku, "CC-5735-01")
        XCTAssertEqual(variant.barcode, "5054131057353")
        XCTAssertEqual(variant.releaseYear, 2023)
        XCTAssertEqual(variant.notes, "Limited edition release")
        XCTAssertEqual(variant.setName, "Holiday Set 2023")
        XCTAssertEqual(variant.epochId, "5735")
        XCTAssertEqual(variant.isPrimary, true)
    }
    
    func testDecodeVariantResponseWithAllNulls() throws {
        let json = """
        {
            "uuid": "test-variant",
            "critter_id": "test-critter",
            "name": "Basic Variant",
            "sku": null,
            "barcode": null,
            "image_url": null,
            "thumbnail_url": null,
            "release_year": null,
            "notes": null,
            "set_id": null,
            "set_name": null,
            "epoch_id": null,
            "created_at": "2026-01-24T14:04:24.000000Z",
            "updated_at": "2026-01-24T14:04:24.000000Z",
            "is_primary": false
        }
        """.data(using: .utf8)!
        
        let variant = try decoder.decode(VariantResponse.self, from: json)
        
        XCTAssertEqual(variant.uuid, "test-variant")
        XCTAssertNil(variant.sku)
        XCTAssertNil(variant.barcode)
        XCTAssertNil(variant.imageUrl)
        XCTAssertNil(variant.releaseYear)
        XCTAssertNil(variant.setName)
        XCTAssertEqual(variant.isPrimary, false)
    }
    
    // MARK: - SetResponse Tests (Barcode Scanner)
    
    func testDecodeSetResponse() throws {
        let json = """
        {
            "set": {
                "uuid": "set-uuid-123",
                "epoch_id": "5735",
                "name": "Flora Rabbit Family Set",
                "release_year": 2022,
                "description": "Complete family set",
                "barcode": "5054131057353"
            },
            "variants": [
                {
                    "uuid": "variant-1",
                    "name": "Nolan Flora",
                    "sku": "CC-5735-01",
                    "barcode": null,
                    "image_url": "https://example.com/nolan.jpg",
                    "thumbnail_url": "https://example.com/nolan_thumb.jpg",
                    "release_year": 2022,
                    "notes": null,
                    "critter": {
                        "uuid": "critter-1",
                        "name": "Nolan Flora",
                        "member_type": "Parents",
                        "role": "Father",
                        "family": {
                            "uuid": "family-1",
                            "name": "Flora Rabbit",
                            "species": "Rabbit"
                        }
                    }
                }
            ],
            "variants_count": 1
        }
        """.data(using: .utf8)!
        
        let response = try decoder.decode(SetResponse.self, from: json)
        
        XCTAssertEqual(response.set.epochId, "5735")
        XCTAssertEqual(response.set.name, "Flora Rabbit Family Set")
        XCTAssertEqual(response.set.barcode, "5054131057353")
        XCTAssertEqual(response.variants.count, 1)
        XCTAssertEqual(response.variants[0].critter.name, "Nolan Flora")
        XCTAssertEqual(response.variants[0].critter.role, "Father")
        XCTAssertEqual(response.variants[0].critter.family.name, "Flora Rabbit")
        XCTAssertEqual(response.variantsCount, 1)
    }
    
    // MARK: - ReportResponse Tests
    
    func testDecodeReportResponse() throws {
        let json = """
        {
            "message": "Report submitted successfully. Thank you for helping improve our database!",
            "data": {
                "uuid": "034d9c75-545f-4ea4-a8b3-b7802721b898"
            },
            "meta": {
                "response_time_ms": 56,
                "count": 1
            }
        }
        """.data(using: .utf8)!
        
        let response = try decoder.decode(ReportResponse.self, from: json)
        
        XCTAssertEqual(response.message, "Report submitted successfully. Thank you for helping improve our database!")
        XCTAssertEqual(response.data.uuid, "034d9c75-545f-4ea4-a8b3-b7802721b898")
    }
    
    // MARK: - PaginationMeta Tests
    
    func testDecodePaginationMeta() throws {
        let json = """
        {
            "current_page": 2,
            "last_page": 5,
            "per_page": 30,
            "total": 149,
            "response_time_ms": 108
        }
        """.data(using: .utf8)!
        
        let meta = try decoder.decode(PaginationMeta.self, from: json)
        
        XCTAssertEqual(meta.currentPage, 2)
        XCTAssertEqual(meta.lastPage, 5)
        XCTAssertEqual(meta.perPage, 30)
        XCTAssertEqual(meta.total, 149)
    }
    
    // MARK: - Error Cases
    
    func testDecodeInvalidJSON() {
        let invalidJSON = "{ invalid json }".data(using: .utf8)!
        
        XCTAssertThrowsError(try decoder.decode(BrowseCritterResponse.self, from: invalidJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testDecodeMissingRequiredField() {
        // Missing required 'name' field
        let json = """
        {
            "uuid": "test-uuid",
            "member_type": "Babies",
            "variants_count": 0
        }
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(try decoder.decode(BrowseCritterResponse.self, from: json)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testDecodeWrongType() {
        // variants_count should be Int, not String
        let json = """
        {
            "uuid": "test-uuid",
            "name": "Test Critter",
            "member_type": "Babies",
            "family_uuid": null,
            "family_name": null,
            "variants_count": "not a number",
            "thumbnail_url": null
        }
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(try decoder.decode(BrowseCritterResponse.self, from: json)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testDecodeEmptyArray() throws {
        let json = """
        {
            "data": [],
            "meta": {
                "current_page": 1,
                "last_page": 1,
                "per_page": 30,
                "total": 0,
                "response_time_ms": 10
            }
        }
        """.data(using: .utf8)!
        
        let response = try decoder.decode(BrowseCrittersAPIResponse.self, from: json)
        
        XCTAssertEqual(response.data.count, 0)
        XCTAssertEqual(response.meta.total, 0)
    }
}