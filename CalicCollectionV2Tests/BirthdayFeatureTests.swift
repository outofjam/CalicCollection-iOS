//
//  BirthdayFeatureTests.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-30.
//


//
//  BirthdayFeatureTests.swift
//  LottaPawsTests
//
//  Created by Claude on 2026-01-30.
//

import XCTest
@testable import CalicCollectionV2

final class BirthdayFeatureTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Clear any stored birthday before each test
        UserDefaults.standard.removeObject(forKey: Config.UserDefaultsKeys.userBirthday)
    }
    
    override func tearDownWithError() throws {
        // Clean up after tests
        UserDefaults.standard.removeObject(forKey: Config.UserDefaultsKeys.userBirthday)
    }
    
    // MARK: - Birthday Format Tests
    
    func testFormatBirthdayForStorage() {
        // Given/When/Then
        XCTAssertEqual(AppSettings.formatBirthdayForStorage(month: 1, day: 1), "01-01")
        XCTAssertEqual(AppSettings.formatBirthdayForStorage(month: 2, day: 14), "02-14")
        XCTAssertEqual(AppSettings.formatBirthdayForStorage(month: 12, day: 25), "12-25")
        XCTAssertEqual(AppSettings.formatBirthdayForStorage(month: 3, day: 5), "03-05")
        XCTAssertEqual(AppSettings.formatBirthdayForStorage(month: 11, day: 30), "11-30")
    }
    
    func testFormatBirthdayForDisplay() {
        // Given/When/Then
        XCTAssertEqual(AppSettings.formatBirthdayForDisplay("01-01"), "January 1")
        XCTAssertEqual(AppSettings.formatBirthdayForDisplay("02-14"), "February 14")
        XCTAssertEqual(AppSettings.formatBirthdayForDisplay("12-25"), "December 25")
        XCTAssertEqual(AppSettings.formatBirthdayForDisplay("07-04"), "July 4")
    }
    
    func testFormatBirthdayForDisplayWithInvalidInput() {
        // Given/When/Then - Invalid formats should return nil
        XCTAssertNil(AppSettings.formatBirthdayForDisplay("invalid"))
        XCTAssertNil(AppSettings.formatBirthdayForDisplay(""))
        XCTAssertNil(AppSettings.formatBirthdayForDisplay("13-01")) // Invalid month
        XCTAssertNil(AppSettings.formatBirthdayForDisplay("00-15")) // Invalid month
        XCTAssertNil(AppSettings.formatBirthdayForDisplay("01-32")) // Invalid day
        XCTAssertNil(AppSettings.formatBirthdayForDisplay("01-00")) // Invalid day
    }
    
    func testFormatBirthdayRoundTrip() {
        // Given
        let month = 6
        let day = 15
        
        // When
        let stored = AppSettings.formatBirthdayForStorage(month: month, day: day)
        let displayed = AppSettings.formatBirthdayForDisplay(stored)
        
        // Then
        XCTAssertEqual(stored, "06-15")
        XCTAssertEqual(displayed, "June 15")
    }
    
    // MARK: - Birthday Matching Tests
    
    func testIsBirthdayMatchWithMatchingBirthdays() {
        // Given
        let appSettings = AppSettings.shared
        appSettings.userBirthday = "02-16"
        
        // When/Then
        XCTAssertTrue(appSettings.isBirthdayMatch("02-16"))
    }
    
    func testIsBirthdayMatchWithNonMatchingBirthdays() {
        // Given
        let appSettings = AppSettings.shared
        appSettings.userBirthday = "02-16"
        
        // When/Then
        XCTAssertFalse(appSettings.isBirthdayMatch("03-15"))
        XCTAssertFalse(appSettings.isBirthdayMatch("02-17"))
        XCTAssertFalse(appSettings.isBirthdayMatch("12-16"))
    }
    
    func testIsBirthdayMatchWithNilUserBirthday() {
        // Given
        let appSettings = AppSettings.shared
        appSettings.userBirthday = nil
        
        // When/Then - Should never match if user hasn't set birthday
        XCTAssertFalse(appSettings.isBirthdayMatch("02-16"))
        XCTAssertFalse(appSettings.isBirthdayMatch("01-01"))
    }
    
    func testIsBirthdayMatchWithNilCritterBirthday() {
        // Given
        let appSettings = AppSettings.shared
        appSettings.userBirthday = "02-16"
        
        // When/Then - Should never match if critter has no birthday
        XCTAssertFalse(appSettings.isBirthdayMatch(nil))
    }
    
    func testIsBirthdayMatchWithBothNil() {
        // Given
        let appSettings = AppSettings.shared
        appSettings.userBirthday = nil
        
        // When/Then
        XCTAssertFalse(appSettings.isBirthdayMatch(nil))
    }
    
    // MARK: - Birthday Display Tests
    
    func testUserBirthdayDisplayWithSetBirthday() {
        // Given
        let appSettings = AppSettings.shared
        appSettings.userBirthday = "07-04"
        
        // When/Then
        XCTAssertEqual(appSettings.userBirthdayDisplay, "July 4")
    }
    
    func testUserBirthdayDisplayWithNoBirthday() {
        // Given
        let appSettings = AppSettings.shared
        appSettings.userBirthday = nil
        
        // When/Then
        XCTAssertNil(appSettings.userBirthdayDisplay)
    }
    
    // MARK: - UserDefaults Persistence Tests
    
    func testBirthdayPersistsToUserDefaults() {
        // Given
        let appSettings = AppSettings.shared
        
        // When
        appSettings.userBirthday = "08-22"
        
        // Then
        let stored = UserDefaults.standard.string(forKey: Config.UserDefaultsKeys.userBirthday)
        XCTAssertEqual(stored, "08-22")
    }
    
    func testBirthdayRemovalFromUserDefaults() {
        // Given
        let appSettings = AppSettings.shared
        appSettings.userBirthday = "08-22"
        
        // When
        appSettings.userBirthday = nil
        
        // Then
        let stored = UserDefaults.standard.string(forKey: Config.UserDefaultsKeys.userBirthday)
        XCTAssertNil(stored)
    }
    
    // MARK: - Edge Cases
    
    func testLeapYearBirthday() {
        // Given
        let appSettings = AppSettings.shared
        appSettings.userBirthday = "02-29"
        
        // When/Then
        XCTAssertTrue(appSettings.isBirthdayMatch("02-29"))
        XCTAssertEqual(appSettings.userBirthdayDisplay, "February 29")
    }
    
    func testBirthdayMatchIsCaseSensitive() {
        // Given - API returns lowercase format
        let appSettings = AppSettings.shared
        appSettings.userBirthday = "02-16"
        
        // When/Then - Exact match required
        XCTAssertTrue(appSettings.isBirthdayMatch("02-16"))
        // These shouldn't happen from API, but test defensively
        XCTAssertFalse(appSettings.isBirthdayMatch("2-16"))
        XCTAssertFalse(appSettings.isBirthdayMatch("02-6"))
    }
    
    // MARK: - Integration with CritterInfo
    
    func testBirthdayMatchWithCritterInfo() {
        // Given
        let appSettings = AppSettings.shared
        appSettings.userBirthday = "03-15"
        
        let critterWithMatchingBirthday = CritterInfo(
            uuid: "test-uuid-1",
            name: "Test Husky",
            memberType: "Kids",
            birthday: "03-15",
            familyName: "Husky Family",
            familyUuid: "family-uuid",
            species: "dog"
        )
        
        let critterWithDifferentBirthday = CritterInfo(
            uuid: "test-uuid-2",
            name: "Test Cat",
            memberType: "Kids",
            birthday: "07-04",
            familyName: "Cat Family",
            familyUuid: "family-uuid-2",
            species: "cat"
        )
        
        let critterWithNoBirthday = CritterInfo(
            uuid: "test-uuid-3",
            name: "Test Fox",
            memberType: "Kids",
            birthday: nil,
            familyName: "Fox Family",
            familyUuid: "family-uuid-3",
            species: "fox"
        )
        
        // When/Then
        XCTAssertTrue(appSettings.isBirthdayMatch(critterWithMatchingBirthday.birthday))
        XCTAssertFalse(appSettings.isBirthdayMatch(critterWithDifferentBirthday.birthday))
        XCTAssertFalse(appSettings.isBirthdayMatch(critterWithNoBirthday.birthday))
    }
}
