//
//  SMLAPI.swift
//  ExposureNotificationApp
//
//

import Foundation
import ExposureNotification

struct EncodableExposureKeys: Encodable {
    let key: String
    let rollingStartNumber: Int
    let rollingPeriod: Int
    let transmissionRisk: Int
}

struct TEKPayload: Encodable {
    let temporaryExposureKeys: [EncodableExposureKeys]
    let regions: [String]
    let appPackageName: String
    let platform: String
    let deviceVerificationPayload: String = "device_token_value"
    let pinToken: String?
    let verificationPayload: String
    let padding: String
}

class SOAPParser: NSObject, XMLParserDelegate {
    var values = [String: String]()
    var currentKey = ""
    public func get(_ key: String) -> String? {
        return values[key]
    }
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentKey = elementName
    }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if values[currentKey] == nil {
            values[currentKey] = string
        }
        else {
            values[currentKey]! += string
        }
    }
}

struct SMLAPI {
    // Server Down Check
    static var LOG_TO_SERVER = true
    static func GetValuesFromSOAPResponse(response: Data, keys: [String]) -> [String?] {
        //let parser = XMLParser(data: response.data(using: .utf8)!)
        let parser = XMLParser(data: response)
        let pDelegate = SOAPParser()
        parser.delegate = pDelegate
        parser.parse()
        return keys.map { key in
            return pDelegate.get(key)
        }
    }
    struct VAValidationResponse {
        let token: String?
        let success: Bool
        init(body: Data) {
            let values = SMLAPI.GetValuesFromSOAPResponse(response: body, keys: ["con:token", "con:response"])
            let rawToken = values[0]
            if let rawToken = rawToken {
                let rawToken = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanedToken = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanedToken.count <= 1 {
                    self.token = nil
                }
                else {
                    self.token = cleanedToken
                }
            }
            else {
                self.token = nil
            }
            if let result = values[1] {
                let result = result.trimmingCharacters(in: .whitespacesAndNewlines)
                self.success = result == "YES"
            }
            else {
                self.success = false
            }
        }
    }
    static func SubmitValidationCodeToVA(code: String, successCB: @escaping (Bool, Int, String?) -> ()) {
        let headers = ["Content-Type": "application/soap+xml;charset=UTF-8;action='urn:VerificationRequest'"]
        let req = NetRequest(NetRequest.Endpoints.TEST_VERIFICATION, method: NetRequest.Methods.POST, delayStart: true, additionalHeaders: headers, resultCB: { (data, err, statusCode) in
            if let data = data {
                if let dataStr = String(data: data, encoding: .utf8) {
                }
                else {
                }
            }
            else {
            }
            if statusCode == 200 {
                guard let data = data else {
                    successCB(false, statusCode, nil)
                    return
                }
                let response = VAValidationResponse(body: data)
                if !response.success {
                    successCB(false, statusCode, nil)
                    return
                }
                if let token = response.token {
                    successCB(true, statusCode, token)
                }
                else {
                    successCB(false, statusCode, nil)
                    return
                }
            }
            else {
                successCB(false, statusCode, nil)
            }
        })
        req.customURLSessionDelegate = VASelfSignedURLSessionDelegate()
        let body = """
        <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:con="ContactTracingTestVerificationWS">
        <soap:Header/>
        <soap:Body>
        <con:VerificationRequest>
        <con:Pin>\(code)</con:Pin>
        <con:VerificationType>I</con:VerificationType>
        </con:VerificationRequest>
        </soap:Body>
        </soap:Envelope>
        """
        req.setRawBody(body)
        req.start()
    }
    static func FetchURLs(cb: @escaping ([URL]) -> ()) {
        self.FetchIndexes { (str) in
            var urls: [URL] = []
            for path in str.components(separatedBy: "\n") {
                let str = "\(SMLConfig.KEYS_BUCKET)\(path)"
                if let url = URL(string: str) {
                    urls.append(url)
                }
            }
            cb(urls.filter({ (url) -> Bool in
                return url.absoluteString.contains(".zip")
            }))
        }
    }
    static func FetchIndexes(cb: @escaping (String) -> ()) {
        _ = NetRequest(SMLConfig.KEYS_INDEX, method: NetRequest.Methods.GET) { (data, err, statusCode) in
            if let data = data {
                if let str = String(data: data, encoding: .utf8) {
                    cb(str)
                }
            }
        }
    }
    enum NetError: Error {
        case contentsNull
        case contentsEmpty
        case httpError
        case parser
    }
    static func FetchToCache(url: URL, cb: @escaping (URL?, Error?) -> ()) {
        _ = NetRequest(url, method: NetRequest.Methods.GET, resultCB: { (data, err, statusCode) in
            if err != nil {
                cb(nil, err)
                return
            }
            if statusCode != 200 {
                cb(nil, NetError.httpError)
                return
            }
            else {
                // HTTP 200 Found
                guard let data = data else {
                    cb(nil, NetError.contentsNull)
                    return
                }
                if data.count <= 0 {
                    cb(nil, NetError.contentsEmpty)
                    return
                }
                // Success
                let cacheDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
                // Create a random 10-character subdirectory name and save files there for extraction
                let rstr = String(format:"%02X", url.hashValue)
                let zipSubdirectory = cacheDirectory.appendingPathComponent(rstr, isDirectory: true)
                
                if(!FileManager.default.fileExists(atPath: zipSubdirectory.path)) {
                    do {
                        try FileManager.default.createDirectory(atPath: zipSubdirectory.path, withIntermediateDirectories: true, attributes: nil)
                        SMLLog(.netRequest, "success creating directory \(zipSubdirectory.path)")
                    }
                    catch {
                    }
                }
                
                let tmpFile = zipSubdirectory.appendingPathComponent("archive.zip", isDirectory: false)
                do {
                    try data.write(to: tmpFile, options: Data.WritingOptions.atomicWrite)
                    cb(tmpFile, nil)
                }
                catch {
                    cb(nil, error)
                }
            }
        })
    }
    static func PostKeys(keys: [ENTemporaryExposureKey], pinToken: String, successCB: @escaping (Bool, String?) -> ()) {
        let postKeysRequest = NetRequest(SMLConfig.UPLOAD_KEYS,
                       method: NetRequest.Methods.POST,
                       delayStart: true,
                       resultCB: { (data, err, statusCode) in
                        if statusCode == 200 {
                            successCB(true, nil)
                        }
                        else {
                            if let data = data {
                                if let str = String(data: data, encoding: .utf8) {
                                    successCB(false, str)
                                }
                                else {
                                    successCB(false, "ERROR HTTP \(statusCode)")
                                }
                            }
                            else {
                                successCB(false, "Unknown Server Error HTTP \(statusCode)")
                            }
                        }
        })
        postKeysRequest.customURLSessionDelegate = PubKeyPinningURLSessionDelegate()
        let temporaryExposureKeys = keys.map { (key) -> EncodableExposureKeys in
            return EncodableExposureKeys(key: key.keyData.base64EncodedString(),
                                         rollingStartNumber: Int("\(key.rollingStartNumber)")!,
                                         rollingPeriod: Int("\(key.rollingPeriod)")!,
                                         transmissionRisk: Int("\(key.transmissionRiskLevel)")!
            )
        }

        let payload = TEKPayload(
            temporaryExposureKeys: temporaryExposureKeys,
            regions: ["US"],
            appPackageName: "gov.vdh.exposurenotification",
            platform: "ios",
            pinToken: pinToken,
            verificationPayload: "SML",
            padding: randomString(minLength: 6, maxLength: 128)
        )
        postKeysRequest.setBody(payload)
        postKeysRequest.start()
    }
}
