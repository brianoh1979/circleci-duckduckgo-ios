//
//  AppHTTPSUpgradeStoreTests.swift
//  DuckDuckGo
//
//  Copyright © 2017 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
@testable import Core
@testable import BrowserServicesKit

final class AppHTTPSUpgradeStoreTests: XCTestCase {

    var testee: AppHTTPSUpgradeStore!

    override func setUp() {
        super.setUp()
        testee = AppHTTPSUpgradeStore()
        testee.reset()
    }
    
    override func tearDown() {
        super.tearDown()
        
        testee.reset()
    }

    /// This may fail after embedded data is updated, fix accordingly
    func testWhenBloomNotPersistedThenEmbeddedSpecificationReturned() {
        let sha = "d72a358afca8f70fd1447009efd9e5e42aa7a4e6a01f593da226dbabef0a0052"
        let specification = HTTPSBloomFilterSpecification(bitCount: 12153347, errorRate: 0.000001, totalEntries: 422649, sha256: sha)
        XCTAssertEqual(specification, testee.loadBloomFilter()?.specification)
    }
    
    /// This may fail after embedded data is updated, fix accordingly
    func testWhenBloomNotPersistedThenEmbeddedBloomUsedAndBloomContainsKnownUpgradableSite() {
        let bloomFilter = testee.loadBloomFilter()?.wrapper
        XCTAssertNotNil(bloomFilter)
        XCTAssertTrue(bloomFilter!.contains("facebook.com"))
    }
    
    /// This may fail after embedded data is updated, fix accordingly
    func testWhenBloomNotPersistedThenEmbeddedBloomUsedAndBloomDoesNotContainAnUnknownSite() {
        let bloomFilter = testee.loadBloomFilter()?.wrapper
        XCTAssertNotNil(bloomFilter)
        XCTAssertFalse(bloomFilter!.contains("anUnkonwnSiteThatIsNotInOurUpgradeList.com"))
    }
    
    /// This may fail after embedded data is updated, fix accordingly
    func testWhenBloomNotPersistedThenEmbeddedBloomUsedAndEmbeddedExcludedDomainIsTrue() {
        let bloomFilter = testee.loadBloomFilter()?.wrapper
        XCTAssertNotNil(bloomFilter)
        XCTAssertTrue(testee.hasExcludedDomain("www.dppps.sc.gov"))
    }
        
    func testWhenNewBloomFilterMatchesShaInSpecThenSpecAndDataPersisted() {
        let data = "Hello World!".data(using: .utf8)!
        let sha = "7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069"
        let specification = HTTPSBloomFilterSpecification(bitCount: 100, errorRate: 0.01, totalEntries: 100, sha256: sha)
        XCTAssertNoThrow(try testee.persistBloomFilter(specification: specification, data: data))
        XCTAssertEqual(specification, testee.loadBloomFilter()?.specification)
    }
    
    func testWhenNewBloomFilterDoesNotMatchShaInSpecThenSpecAndDataNotPersisted() {
        let data = "Hello World!".data(using: .utf8)!
        let sha = "wrong sha"
        let specification = HTTPSBloomFilterSpecification(bitCount: 100, errorRate: 0.01, totalEntries: 100, sha256: sha)

        customAssertionFailure = { _, _, _ in }
        defer { customAssertionFailure = nil }
        XCTAssertThrowsError(try testee.persistBloomFilter(specification: specification, data: data))
        XCTAssertNotEqual(specification, testee.loadBloomFilter()?.specification)
    }

    func testWhenBloomFilterSpecificationIsPersistedThenSpecificationIsRetrieved() throws {
        let specification = HTTPSBloomFilterSpecification(bitCount: 100, errorRate: 0.01, totalEntries: 100, sha256: "abc")
        try testee.persistBloomFilterSpecification(specification)
        let storedSpecification = testee.loadStoredBloomFilterSpecification()
        XCTAssertEqual(specification, storedSpecification)
    }
    
    func testWhenBloomFilterSpecificationIsPersistedThenOldSpecificationIsReplaced() throws {
        let originalSpecification =  HTTPSBloomFilterSpecification(bitCount: 100, errorRate: 0.01, totalEntries: 100, sha256: "abc")
        try testee.persistBloomFilterSpecification(originalSpecification)

        let newSpecification = HTTPSBloomFilterSpecification(bitCount: 101, errorRate: 0.01, totalEntries: 101, sha256: "abc")
        try testee.persistBloomFilterSpecification(newSpecification)

        let storedSpecification = testee.loadStoredBloomFilterSpecification()
        XCTAssertEqual(newSpecification, storedSpecification)
    }
    
    func testWhenExcludedDomainsPersistedThenExcludedDomainIsTrue() throws {
        try testee.persistExcludedDomains([ "www.example.com", "apple.com" ])
        XCTAssertTrue(testee.hasExcludedDomain("www.example.com"))
        XCTAssertTrue(testee.hasExcludedDomain("apple.com"))
    }
    
    func testWhenNoExcludedDomainsPersistedThenExcludedDomainIsFalse() {
        XCTAssertFalse(testee.hasExcludedDomain("www.example.com"))
        XCTAssertFalse(testee.hasExcludedDomain("apple.com"))
    }
    
    func testWhenExcludedDomainsPersistedThenOldDomainsAreDeleted() throws {
        try testee.persistExcludedDomains([ "www.old.com", "otherold.com" ])
        try testee.persistExcludedDomains([ "www.new.com", "othernew.com" ])
        XCTAssertFalse(testee.hasExcludedDomain("www.old.com"))
        XCTAssertFalse(testee.hasExcludedDomain("otherold.com"))
        XCTAssertTrue(testee.hasExcludedDomain("www.new.com"))
        XCTAssertTrue(testee.hasExcludedDomain("othernew.com"))
    }
    
}
