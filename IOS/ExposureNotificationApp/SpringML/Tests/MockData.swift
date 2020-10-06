//
//  MockData.swift
//  ExposureNotificationApp
//
//

import Foundation

struct MockData {
    static let haValidationMockResponse = """
        <soapenv:Envelope xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope">
        <soapenv:Body>
           <con:VerificationRequestResponse xmlns:con="ContactTracingTestVerificationWS">
              <con:response>YES</con:response>
              <!--Optional:-->
              <con:token>TODO</con:token>
           </con:VerificationRequestResponse>
        </soapenv:Body>
    """.trimmingCharacters(in: .whitespacesAndNewlines)
    static let haValidationMockResponseData = MockData.haValidationMockResponse.data(using: .utf8)!
    static let haValidationMockToken = "TODO".trimmingCharacters(in: .whitespacesAndNewlines)
    static let haValidationMockTokenData = MockData.haValidationMockToken.data(using: .utf8)!
}
