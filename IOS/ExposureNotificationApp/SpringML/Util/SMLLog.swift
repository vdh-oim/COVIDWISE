//
//  SMLLog.swift
//  ExposureNotificationApp
//
//

import Foundation
//import FirebaseDatabase

let BUILD_ID="ios-build-33" // Auto-generated build id

enum SMLLogBucket: String {
    case remoteKeyManager = "remoteKeyManager"
    case deviceUtil = "deviceUtil"
    case netRequest = "netRequest"
    case smlApi = "smlApi"
}

// Enable/disbale logging for buckets
let SMLLogConfig: [SMLLogBucket: Bool] = [
    .remoteKeyManager: true,
    .deviceUtil: false,
    .netRequest: false,
    .smlApi: false
]

func SMLLog(_ bucket: SMLLogBucket, _ str: String) {
    if let bucketEnabled = SMLLogConfig[bucket] {
        if(bucketEnabled) {
        }
    }
}

let df = DateFormatter()
let uuid_identifier = UUID().uuidString

func postLog(_ event_name: String){
    
    if !BackgroundSession.shared.LOG_TO_SERVER{
        return
    }
    let t = "\(Int(Date().timeIntervalSince1970 * 1000))"
    df.dateFormat = "EEE MMM d HH:mm:ss ZZZZ SSSS yyyy"
    let date = df.string(from: Date())
    var input:[String:String] = [String:String]()
    input["type"] = "IOS"
    input["user"] = uuid_identifier
    input["timestamp"] = t
    input["message"] = "\(date) : \(event_name)"
    var request = URLRequest(url: SMLConfig.POST_MESSAGES, cachePolicy: .useProtocolCachePolicy, timeoutInterval: NetRequest.Configuration.timeout)
     request.httpMethod = "POST"
     request.setValue("application/json", forHTTPHeaderField: "Accept")
     request.addValue("application/json", forHTTPHeaderField: "Content-Type")
     var body: Data?
     body  = try! JSONEncoder().encode(input)
    if let body = body {
        request.httpBody = body
        do{
            _ = try BackgroundSession.shared.postLogstoServer(for: request, from: body)
        }catch{
            
        }
    }
}
