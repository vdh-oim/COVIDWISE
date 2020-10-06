//
//  RemoteKeyManagerTestCases.swift
//  ENTests
//
//

import XCTest

class RemoteKeyManagerTestCases: XCTestCase {
    func testRefreshKeys() {
        let expectIndexes = XCTestExpectation(description: "Should get new key indexes")
        let expectNewIndexesOnDisk = XCTestExpectation(description: "Should get new key indexes stored to disk")
        let expectEmptyIndexesAfterRefresh = XCTestExpectation(description: "Should get 0 new key indexes after just retrieving them")
        let rkm = RemoteKeyManager.shared
        rkm.eraseDataStore()
        rkm.refreshKeys { (count) in
            XCTAssert(count == 3, "Expected 3 new indexes")
            expectIndexes.fulfill()
            
            // We should see a new index is now stored on disk // TODO: I believe this is meant to be in cache directory, and ephemeral after uploading to the SDK, but will need to check after getting Entitlements
            var firstFoundKey: String? = nil
            for (key, _) in rkm.allKnownKeys {
                if(firstFoundKey == nil) {
                    firstFoundKey = key
                }
            }
            let localURL = rkm.localURL(forKey: firstFoundKey!)!
            let localURLContents = try! String(contentsOf: localURL)
            let localURLHasContents = localURLContents.count > 5
            XCTAssert(localURLHasContents, "File \(localURL) should exist")
            expectNewIndexesOnDisk.fulfill()
            
            // If we try again we shouldn't expect any new keys
            rkm.refreshKeys { (count) in
                XCTAssert(count == 0, "Expected 0 new indexes")
                expectEmptyIndexesAfterRefresh.fulfill()
            }
        }
        wait(for: [expectIndexes, expectEmptyIndexesAfterRefresh, expectNewIndexesOnDisk], timeout: NetRequest.Configuration.timeout + 5)
    }
    func testNewIndexesFromRemote() throws {
        let expectIndexes = XCTestExpectation(description: "Should get remote key indexes")
        let rkm = RemoteKeyManager.shared
        rkm.eraseDataStore()
        rkm.getNewIndexesFromRemote { (urls) in
            XCTAssert(urls.count > 2, "Expect more than 2 test urls")
            expectIndexes.fulfill()
        }
        wait(for: [expectIndexes], timeout: NetRequest.Configuration.timeout + 1)
    }
    func testGetIndexesFromRemote() throws {
        let expectIndexes = XCTestExpectation(description: "Should get remote key indexes")
        let rkm = RemoteKeyManager.shared
        rkm.getIndexesFromRemote { (urls) in
            XCTAssert(urls.count > 10, "Expect more than 10 test urls")
            expectIndexes.fulfill()
        }
        wait(for: [expectIndexes], timeout: NetRequest.Configuration.timeout + 1)
    }
    func testReadKeysFromDisk() throws {
        let rkm = RemoteKeyManager.shared
        let indexes = rkm.allKnownKeys
        XCTAssert(true)
    }

}
