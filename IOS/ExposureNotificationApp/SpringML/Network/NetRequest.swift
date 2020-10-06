//
//  NetRequest.swift
//  ExposureNotificationApp
//
//

import Foundation

class NetRequest {    
    // Implementation
    let request: URLRequest
    public var customURLSessionDelegate: URLSessionDelegate?
    let resultCB: (Data?, Error?, Int) -> ()
    let method: String
    var body: Data?
    func setRawBody(_ body: String) {
        self.body = body.data(using: .utf8)!
    }
    func setBody<T: Encodable>(_ obj: T) {
        self.body = try! JSONEncoder().encode(obj)
        if let body = self.body {
            
        }
    }
    struct Methods {
        static let GET = "GET"
        static let POST = "POST"
    }
    init(_ endpoint: URL, method: String, delayStart: Bool = false, additionalHeaders: [String: String]?, resultCB: @escaping (Data?, Error?, Int) -> ()) {
        if(NetRequest.Configuration.verbose) {
            
        }
        var request = URLRequest(url: endpoint, cachePolicy: .useProtocolCachePolicy, timeoutInterval: NetRequest.Configuration.timeout)
        request.httpMethod = method
        if let additionalHeaders = additionalHeaders {
            for (value, key) in additionalHeaders {
                request.setValue(key, forHTTPHeaderField: value)
            }
        }
        else {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        self.request = request
        self.resultCB = resultCB
        self.method = method
        if(!delayStart) {
            self.start()
        }
        else {
            
        }
    }
    convenience init(_ endpoint: URL, method: String, delayStart: Bool = false, resultCB: @escaping (Data?, Error?, Int) -> ()) {
        self.init(endpoint, method: method, delayStart: delayStart, additionalHeaders: nil, resultCB: resultCB)
    }
    convenience init(_ endpoint: URL, method: String, resultCB: @escaping (Data?, Error?, Int) -> ()) {
        if(NetRequest.Configuration.verbose) {
        }
        self.init(endpoint, method: method, delayStart: false, resultCB: resultCB)
    }
    func start() {
        if(NetRequest.Configuration.verbose) {
        }
        let completionCB: ((Data?, URLResponse?, Error?) -> Void) = { (data, urlResponse, error) in
            if let error = error {
                if(NetRequest.Configuration.verbose) {
                }
                self.resultCB(nil, error, 400)
            }
            else if let urlResponse = urlResponse {
                
                if(NetRequest.Configuration.verbose) {
                }
                if let data = data {
                    if let httpResponse = urlResponse as? HTTPURLResponse {
                        self.resultCB(data, nil, httpResponse.statusCode)
                    }
                    else {
                        if(NetRequest.Configuration.verbose) {
                        }
                        self.resultCB(data, nil, 400)
                    }
                }
            }
        }
        if(self.method == Methods.POST) {
            if(NetRequest.Configuration.verbose) {
            }
            
            var session = URLSession.shared
            if let customURLSessionDelegate = customURLSessionDelegate {
                session = URLSession(configuration: .default, delegate: customURLSessionDelegate, delegateQueue: nil)
            }
            if let body = body {
                session.uploadTask(with: request, from: body, completionHandler: completionCB).resume()
            }
            else {
                
            }
        }
        else {
            if(NetRequest.Configuration.verbose) {
               
            }
            var session = URLSession.shared
            if let customURLSessionDelegate = customURLSessionDelegate {
                session = URLSession(configuration: .default, delegate: customURLSessionDelegate, delegateQueue: nil)
            }
            session.dataTask(with: request, completionHandler: completionCB).resume()
        }
    }
}

