

import UIKit

class BackgroundSession: NSObject {
   var savedCompletionHandler: (() -> Void)?
   static var shared = BackgroundSession()
   private var session: URLSession!
   var LOG_TO_SERVER:Bool = true

   private override init() {
       super.init()
       let identifier = Bundle.main.bundleIdentifier! + ".postLog"
       let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
       session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
   }
}
extension BackgroundSession {
    @discardableResult
    func postLogstoServer(for request: URLRequest, from data: Data) throws -> URLSessionUploadTask {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        try data.write(to: fileURL)
        let task = session.uploadTask(with: request, fromFile: fileURL)
        task.resume()
        return task
    }
}
extension BackgroundSession: URLSessionDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.savedCompletionHandler?()
            self.savedCompletionHandler = nil
        }
    }
}

extension BackgroundSession: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            self.LOG_TO_SERVER = false
            return
        }
    }
}

extension BackgroundSession: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    }
}
