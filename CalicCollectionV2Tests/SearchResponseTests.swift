//
//  SearchResponseTests.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-30.
//


//
//  SearchTests.swift
//  LottaPawsTests
//
//  Unit tests for search functionality with grouped critter results
//

import XCTest
@testable import CalicCollectionV2

final class SearchResponseTests: XCTestCase {
    
    // MARK: - CritterSearchResult Decoding
    
    func test_decodesFullCritterSearchResult() throws {
        let json = """
        {
            "critter_uuid": "abc-123",
            "critter_name": "Flora Rabbit",
            "member_type": "Babies",
            "birthday": "December 3",
            "hobby": "Painting",
            "family_uuid": "def-456",
            "family_name": "Flora Rabbit",
            "species": "Rabbit",
            "thumbnail_url": "https://example.com/thumb.jpg",
            "matching_variants_count": 2,
            "matching_variants": [
                {
                    "variant_uuid": "v1",
                    "variant_name": "Original Release",
                    "set_name": "Classic Set",
                    "epoch_id": "CC-2024",
                    "release_year": 2024,
                    "thumbnail_url": "https://example.com/v1.jpg"
                },
                {
                    "variant_uuid": "v2",
                    "variant_name": "Christmas Edition",
                    "set_name": "Holiday Set",
                    "epoch_id": "HC-2024",
                    "release_year": 2024,
                    "thumbnail_url": "https://example.com/v2.jpg"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let result = try JSONDecoder().decode(CritterSearchResult.self, from: json)
        
        XCTAssertEqual(result.critterUuid, "abc-123")
        XCTAssertEqual(result.critterName, "Flora Rabbit")
        XCTAssertEqual(result.memberType, "Babies")
        XCTAssertEqual(result.birthday, "December 3")
        XCTAssertEqual(result.hobby, "Painting")
        XCTAssertEqual(result.familyUuid, "def-456")
        XCTAssertEqual(result.familyName, "Flora Rabbit")
        XCTAssertEqual(result.species, "Rabbit")
        XCTAssertEqual(result.thumbnailUrl, "https://example.com/thumb.jpg")
        XCTAssertEqual(result.matchingVariantsCount, 2)
        XCTAssertEqual(result.matchingVariants.count, 2)
        XCTAssertEqual(result.id, "abc-123")
    }
    
    func test_decodesMinimalCritterSearchResult() throws {
        let json = """
        {
            "critter_uuid": "abc-123",
            "critter_name": "Flora Rabbit",
            "member_type": "Babies",
            "birthday": null,
            "hobby": null,
            "family_uuid": null,
            "family_name": null,
            "species": null,
            "thumbnail_url": null,
            "matching_variants_count": 1,
            "matching_variants": []
        }
        """.data(using: .utf8)!
        
        let result = try JSONDecoder().decode(CritterSearchResult.self, from: json)
        
        XCTAssertEqual(result.critterUuid, "abc-123")
        XCTAssertEqual(result.critterName, "Flora Rabbit")
        XCTAssertNil(result.birthday)
        XCTAssertNil(result.hobby)
        XCTAssertNil(result.familyUuid)
        XCTAssertNil(result.familyName)
        XCTAssertNil(result.species)
        XCTAssertNil(result.thumbnailUrl)
        XCTAssertEqual(result.matchingVariantsCount, 1)
        XCTAssertTrue(result.matchingVariants.isEmpty)
    }
    
    // MARK: - MatchingVariant Decoding
    
    func test_decodesFullMatchingVariant() throws {
        let json = """
        {
            "variant_uuid": "v1-uuid",
            "variant_name": "Christmas Set 2024",
            "set_name": "Holiday Collection",
            "epoch_id": "HC-2024",
            "release_year": 2024,
            "thumbnail_url": "https://example.com/thumb.jpg"
        }
        """.data(using: .utf8)!
        
        let variant = try JSONDecoder().decode(MatchingVariant.self, from: json)
        
        XCTAssertEqual(variant.variantUuid, "v1-uuid")
        XCTAssertEqual(variant.variantName, "Christmas Set 2024")
        XCTAssertEqual(variant.setName, "Holiday Collection")
        XCTAssertEqual(variant.epochId, "HC-2024")
        XCTAssertEqual(variant.releaseYear, 2024)
        XCTAssertEqual(variant.thumbnailUrl, "https://example.com/thumb.jpg")
        XCTAssertEqual(variant.id, "v1-uuid")
    }
    
    func test_decodesMinimalMatchingVariant() throws {
        let json = """
        {
            "variant_uuid": "v1-uuid",
            "variant_name": "Original",
            "set_name": null,
            "epoch_id": null,
            "release_year": null,
            "thumbnail_url": null
        }
        """.data(using: .utf8)!
        
        let variant = try JSONDecoder().decode(MatchingVariant.self, from: json)
        
        XCTAssertEqual(variant.variantUuid, "v1-uuid")
        XCTAssertEqual(variant.variantName, "Original")
        XCTAssertNil(variant.setName)
        XCTAssertNil(variant.epochId)
        XCTAssertNil(variant.releaseYear)
        XCTAssertNil(variant.thumbnailUrl)
    }
    
    // MARK: - SearchPaginationMeta Decoding
    
    func test_decodesSearchPaginationMeta() throws {
        let json = """
        {
            "current_page": 1,
            "last_page": 5,
            "per_page": 20,
            "total": 87,
            "total_variants_matched": 142,
            "response_time_ms": 45
        }
        """.data(using: .utf8)!
        
        let meta = try JSONDecoder().decode(SearchPaginationMeta.self, from: json)
        
        XCTAssertEqual(meta.currentPage, 1)
        XCTAssertEqual(meta.lastPage, 5)
        XCTAssertEqual(meta.perPage, 20)
        XCTAssertEqual(meta.total, 87)
        XCTAssertEqual(meta.totalVariantsMatched, 142)
        XCTAssertEqual(meta.responseTimeMs, 45)
    }
    
    func test_decodesSearchPaginationMetaWithNullResponseTime() throws {
        let json = """
        {
            "current_page": 1,
            "last_page": 1,
            "per_page": 20,
            "total": 0,
            "total_variants_matched": 0,
            "response_time_ms": null
        }
        """.data(using: .utf8)!
        
        let meta = try JSONDecoder().decode(SearchPaginationMeta.self, from: json)
        
        XCTAssertEqual(meta.total, 0)
        XCTAssertEqual(meta.totalVariantsMatched, 0)
        XCTAssertNil(meta.responseTimeMs)
    }
    
    // MARK: - Full API Response Decoding
    
    func test_decodesFullSearchAPIResponse() throws {
        let json = """
        {
            "data": [
                {
                    "critter_uuid": "c1",
                    "critter_name": "Flora Rabbit",
                    "member_type": "Babies",
                    "birthday": "December 3",
                    "hobby": "Painting",
                    "family_uuid": "f1",
                    "family_name": "Flora Rabbit",
                    "species": "Rabbit",
                    "thumbnail_url": "https://example.com/flora.jpg",
                    "matching_variants_count": 2,
                    "matching_variants": [
                        {
                            "variant_uuid": "v1",
                            "variant_name": "Christmas Set",
                            "set_name": "Holiday",
                            "epoch_id": "H-24",
                            "release_year": 2024,
                            "thumbnail_url": null
                        }
                    ]
                }
            ],
            "meta": {
                "current_page": 1,
                "last_page": 1,
                "per_page": 20,
                "total": 1,
                "total_variants_matched": 2,
                "response_time_ms": 32
            }
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(CritterSearchAPIResponse.self, from: json)
        
        XCTAssertEqual(response.data.count, 1)
        XCTAssertEqual(response.data[0].critterName, "Flora Rabbit")
        XCTAssertEqual(response.data[0].matchingVariants.count, 1)
        XCTAssertEqual(response.meta.total, 1)
        XCTAssertEqual(response.meta.totalVariantsMatched, 2)
    }
    
    func test_decodesEmptySearchResponse() throws {
        let json = """
        {
            "data": [],
            "meta": {
                "current_page": 1,
                "last_page": 1,
                "per_page": 20,
                "total": 0,
                "total_variants_matched": 0,
                "response_time_ms": 12
            }
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(CritterSearchAPIResponse.self, from: json)
        
        XCTAssertTrue(response.data.isEmpty)
        XCTAssertEqual(response.meta.total, 0)
        XCTAssertEqual(response.meta.totalVariantsMatched, 0)
    }
}

// MARK: - Search Result Identifiable Tests

final class SearchResultIdentifiableTests: XCTestCase {
    
    func test_critterSearchResultId() {
        let result = CritterSearchResult(
            critterUuid: "unique-uuid-123",
            critterName: "Test",
            memberType: "Baby",
            birthday: nil,
            hobby: nil,
            familyUuid: nil,
            familyName: nil,
            species: nil,
            thumbnailUrl: nil,
            matchingVariantsCount: 0,
            matchingVariants: []
        )
        
        XCTAssertEqual(result.id, "unique-uuid-123")
    }
    
    func test_matchingVariantId() {
        let variant = MatchingVariant(
            variantUuid: "variant-uuid-456",
            variantName: "Test Variant",
            setName: nil,
            epochId: nil,
            releaseYear: nil,
            thumbnailUrl: nil
        )
        
        XCTAssertEqual(variant.id, "variant-uuid-456")
    }
}
