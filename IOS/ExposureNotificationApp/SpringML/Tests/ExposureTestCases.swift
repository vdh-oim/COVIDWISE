//
//  ExposureTestCases.swift
//  ENTests
//
//

import XCTest

class ExposureTestCases: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAssumptions() throws {
        let daysSinceExposure: Double = 2
        let timeIntervalSinceLastExposure = daysSinceExposure * 24.0 * 60.0 * 60.0 //  2 days ago
        let lastExposure = Date().advanced(by: -timeIntervalSinceLastExposure)
        LocalStore.shared.dateOfPositiveExposure = lastExposure
    }

}
