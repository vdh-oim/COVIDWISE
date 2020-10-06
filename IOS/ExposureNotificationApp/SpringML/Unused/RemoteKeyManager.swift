//
//  RemoteKeyManager.swift
//  ExposureNotificationApp
//
//

import Foundation
import Combine

// This is unused because the server provides a 14-day history, which ended up being the end desired result
class RemoteKeyManager {
    
    public var allKnownKeys: [String: Bool] = [:]
    
    static let shared = RemoteKeyManager()
    init() {
        let allKeysOnDisk = try! self.indexesOnDisk()
        for key in allKeysOnDisk {
            allKnownKeys[key] = true
        }
    }
    // High level API
    func refreshKeys(_ done: @escaping (_ newKeys: Int) -> ()) {
        self.getNewIndexesFromRemote { (urls) in
            let downloadGroup = DispatchGroup()
            
            var updatedKeysCount = 0
            for url in urls {
                downloadGroup.enter()
                _ = NetRequest.init(url, method: NetRequest.Methods.GET) { (data, err, statusCode) in
                    if let err = err {
                    }
                    if let data = data {
                        // Write to disk
                        try! data.write(to: self.localURL(forKey: url.absoluteString)!) // TODO: A little more error handling
                        self.allKnownKeys[url.absoluteString] = true
                        updatedKeysCount += 1
                        downloadGroup.leave()
                    }
                }
            }
            downloadGroup.wait()
            // Now synchronize persistent store
            try! self.storeKeysToDisk()
            done(updatedKeysCount)
        }
    }
    
    // For testing purposes
    func eraseDataStore() {
        let docsPath = getStoreURL()
        try! "".write(to: docsPath, atomically: true, encoding: .utf8)
        self.allKnownKeys = [:]
    }
    
    // Implementation
    func localURL(forKey key: String) -> URL? {
        let docsPath = getDocumentsDirectory()
        let keysPath = docsPath.appendingPathComponent("keyCache", isDirectory: true)
        if let b64OfKeyString = key.data(using: .utf8)?.base64EncodedString() {
            return keysPath.appendingPathComponent(b64OfKeyString, isDirectory: false)
        }
        return nil
    }
    private func getStoreURL() -> URL {
        let docsPath = getDocumentsDirectory()
        SMLLog(.remoteKeyManager, "Documents directory: \(docsPath)")
        return docsPath.appendingPathComponent("keysIndexCache", isDirectory: false)
    }
    private func storeKeysToDisk() throws {
        let dataStoreURL = getStoreURL()
        var dataStoreContents = ""
        for (key, _) in self.allKnownKeys {
            dataStoreContents += "\(key)\n"
        }
        try dataStoreContents.write(to: dataStoreURL, atomically: true, encoding: .utf8)
    }
    private func indexesOnDisk() throws -> [String] {
        let dataStorePath = getStoreURL()
        SMLLog(.remoteKeyManager, "Index history data store path: \(dataStorePath)")
        do {
            let localIndexContents = try String(contentsOf: dataStorePath)
            SMLLog(.remoteKeyManager, "Index contents :\n\(localIndexContents)")
            let keys = localIndexContents.components(separatedBy: "\n").filter { (key) -> Bool in
                return key.count > 1
            }
            SMLLog(.remoteKeyManager, "Keys :\n\(keys)")
            return keys
        }
        catch {
            let err = error as NSError
            if err.code == 260 {
                // File doesn't exist. This is expected before the first save occurs.
                // Create an empty file
                try "".write(to: dataStorePath, atomically: true, encoding: .utf8)
                return []
            }
            else {
                throw error
            }
        }
    }
    enum GetIndexError: Error {
        case generic
        case noURLS
    }
    func getIndexesFromRemoteCombine() {
        /*let fetchResult = Future<[URL], GetIndexError> { promise in
            SMLAPI.FetchIndexes { (filesStr) in
                let files = filesStr.split(separator: Character("\n"))
                if(files.count < 1) {
                    SMLLog(.remoteKeyManager, "Less than 1 file returned from indexes. This isn't right")
                }
                cb(
                    files.map({ (filePath) -> URL? in
                        let urlPath = "http://35.186.235.67/\(filePath)"
                        if let url = URL(string: urlPath) {
                            SMLLog(.remoteKeyManager, "Found URL: \(url)")
                            return url
                        }
                        else {
                            SMLLog(.remoteKeyManager, "Invalid URL \(urlPath) encountered when constructing index URLs") // TODO: Firebase analytics push
                            return nil
                        }
                    }).compactMap({ (url) -> URL in
                        return url!
                    })
                )
            }
        }
        */
    }
    func getIndexesFromRemote(_ cb: @escaping ( ([URL]) -> ())) {
        SMLAPI.FetchIndexes { (filesStr) in
            let files = filesStr.split(separator: Character("\n"))
            if(files.count < 1) {
                SMLLog(.remoteKeyManager, "Less than 1 file returned from indexes. This isn't right")
            }
            cb(
                files.map({ (filePath) -> URL? in
                    let urlPath = "TODO"
                    if let url = URL(string: urlPath) {
                        SMLLog(.remoteKeyManager, "Found URL: \(url)")
                        return url
                    }
                    else {
                        SMLLog(.remoteKeyManager, "Invalid URL \(urlPath) encountered when constructing index URLs") // TODO: Firebase analytics push
                        return nil
                    }
                }).filter({ (url) -> Bool in
                    return url != nil
                }).map({ (url) -> URL in
                    return url!
                })
            )
        }
    }
    func getNewIndexesFromRemote(_ cb: @escaping (( [URL] )) -> ()) {
        self.getIndexesFromRemote { (urls) in
            var newURLs: [URL] = []
            
            let firstThreeURLs = urls[0..<3] // TODO: remove
            for url in firstThreeURLs {      // TODO: use urls instead of firstThreeURLs (IMPORTANT)
                if self.allKnownKeys[url.absoluteString] == nil {
                    newURLs.append(url)
                }
                else {
                }
            }
            cb(newURLs)
        }
    }
}
