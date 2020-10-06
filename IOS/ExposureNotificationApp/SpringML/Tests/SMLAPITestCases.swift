//
//  SMLAPITestCase.swift
//  ExposureNotificationApp
//
//

import XCTest
import ExposureNotification

class SMLAPITestCases: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testParseAuthorizationSOAPResponse() throws {
        let mockResponse = MockData.haValidationMockResponseData
        let mockToken = MockData.haValidationMockToken
        let validationResponse = SMLAPI.VAValidationResponse(body: mockResponse)
        
        XCTAssertNotNil(validationResponse.token, "Expected to parse token")
        XCTAssertEqual(validationResponse.token!, mockToken)
        XCTAssert(validationResponse.success, "Expected success: true")
    }
    
    func testValidReportAuthorizationKey() throws {
        let expectedlyFailedValidation = XCTestExpectation(description: "Validation for bad value failed")
        let code = "150271"
        SMLAPI.SubmitValidationCodeToVA(code: code) { (success, httpStatusCode, token) in
            if(success) {
                expectedlyFailedValidation.fulfill()
            }
            else {
                XCTAssert(false, "Expected successful validation code -- Note this test fails without a unique code. Exclude from automated testing.")
            }
        }
        wait(for: [expectedlyFailedValidation], timeout: NetRequest.Configuration.timeout + 1)
    }
    
    func testInvalidReportAuthorizationKey() throws {
        let expectedlyFailedValidation = XCTestExpectation(description: "Validation for bad value failed")
        let code = "123456"
        SMLAPI.SubmitValidationCodeToVA(code: code) { (success, httpStatusCode, token) in
            if(!success) {
                expectedlyFailedValidation.fulfill()
            }
            else {
                XCTAssert(false, "Expected unsuccessful validation code")
            }
        }
        wait(for: [expectedlyFailedValidation], timeout: NetRequest.Configuration.timeout + 1)
    }
    
    func testPostTestResult() throws {
        let didPost = XCTestExpectation(description: "Posted keys to backend")
        //SMLAPI.PostKeys(keys: [], pinToken: MockData.haValidationMockToken) { (success) in
        SMLAPI.PostKeys(keys: [], pinToken: "badPinToken") { (success, errorMsg) in
            if(!success) {
                XCTAssert(false, "Could not post keys successfully")
            }
            else {
                didPost.fulfill()
            }
        }
        wait(for: [didPost], timeout: NetRequest.Configuration.timeout + 1)
    }
    
    func testPostKeys() throws {
        let didPost = XCTestExpectation(description: "Posted keys to backend")
        ExposureManager.shared.getAndPostTestDiagnosisKeys { error in
            if let error = error {
                XCTAssert(false, "Could not post keys successfully")
            }
            else {
                didPost.fulfill()
            }
        }
        /*SMLAPI.PostKeys( { (success) in
            XCTAssert(success, "Could not post keys successfully")
            didPost.fulfill()
        }*/
        //try! JSONEncoder().encode(obj)
        wait(for: [didPost], timeout: NetRequest.Configuration.timeout + 1)
    }

    func testIndexRetrieval() throws {
        let verifiedIndexes = XCTestExpectation(description: "Retrieved key indexes from backend")
        let testPath = "TODO"
        let randomPathExists = XCTestExpectation(description: "Expected to find \(testPath)")
        SMLAPI.FetchIndexes { (filesStr) in
            let files = filesStr.split(separator: Character("\n"))
            // A random path that is expected in the test data - subject to change
            var foundTestPath = false
            if(files.count > 1) {
                verifiedIndexes.fulfill()
            }
            for filePath in files {
                let urlPath = "http://35.186.235.67/\(filePath)"
                if let url = URL(string: urlPath) {
                    if url.absoluteString == testPath {
                        foundTestPath = true
                        randomPathExists.fulfill()
                    }
                }
                else {
                    XCTAssert(false, "Invalid URL \(urlPath) encountered when constructing index URLs")
                }
            }
            XCTAssert(foundTestPath, "Did not find test path \(testPath)")
        }
        wait(for: [verifiedIndexes, randomPathExists], timeout: NetRequest.Configuration.timeout + 1)
    }
    
    func testDeviceCheck() throws {
        let gotDeviceID = XCTestExpectation(description: "Retrieved Device ID from Device Check")
        DeviceUtil.getDeviceCheckTokenAsB64String( { (str) in
            if let str = str {
                if(str.count > 50) {
                    gotDeviceID.fulfill()
                }
            }
            else {
                XCTAssert(false, "No data in device check callback")
            }
        })
        wait(for: [gotDeviceID], timeout: NetRequest.Configuration.timeout + 1)
    }

}
