/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class representing a local server that vends exposure data.
*/

import Foundation
import ExposureNotification
import CommonCrypto
import Zip

struct CodableDiagnosisKey: Codable, Equatable {
    let keyData: Data
    let rollingPeriod: ENIntervalNumber
    let rollingStartNumber: ENIntervalNumber
    let transmissionRiskLevel: ENRiskLevel
}

struct CodableExposureConfiguration: Codable {
    let minimumRiskScore: ENRiskScore
    let attenuationDurationThresholds: [Int]
    let attenuationLevelValues: [ENRiskLevelValue]
    let daysSinceLastExposureLevelValues: [ENRiskLevelValue]
    let durationLevelValues: [ENRiskLevelValue]
    let transmissionRiskLevelValues: [ENRiskLevelValue]
}

// Replace this class with your own class that communicates with your server.
class Server {
    
    static let shared = Server()
    
    // For testing purposes, this object stores all of the TEKs it receives locally on device
    // In a real implementation, these would be stored on a remote server
    @Persisted(userDefaultsKey: "diagnosisKeys", notificationName: .init("ServerDiagnosisKeysDidChange"), defaultValue: [])
    var diagnosisKeys: [CodableDiagnosisKey]
    func getDiagnosisKeyFileURLs(startingAt index: Int, completion: @escaping (Result<[URL], Error>) -> Void) {
        SMLAPI.FetchURLs { (urls) in
            completion(.success(urls))
        }
    }
    enum ServerError: Error {
        case generic
        case cacheDataRead
        case unexpectedKeyFileZip
        case invalidPIN
    }
    struct ExtractedKeys {
        let bin: URL
        let sig: URL
    }
    static func extractKeysFromZip(_ url: URL, _ completion: @escaping ((ExtractedKeys?) -> Void)) {
        var outFilesMap: [String: URL] = [:]
        let outDir = url.deletingLastPathComponent()
        do {
            try Zip.unzipFile(url,
                      destination: outDir,
                      overwrite: true,
                      password: nil,
                      progress: { (progressValue) in
                        if(progressValue >= 1.0) {
                            if let bin = outFilesMap["export.bin"] {
                                if let sig = outFilesMap["export.sig"] {
                                    // Both files present, we are done
                                    // Just kidding, we need to give them unique filenames now
                                    let randomName = randomString(minLength: 16, maxLength: 16)
                                    
                                    // Move the bin/sig files
                                    let bin = URL(fileURLWithPath: bin.path)
                                    let sig = URL(fileURLWithPath: sig.path)
                                    let binDestinationPath = bin.deletingLastPathComponent().appendingPathComponent("\(randomName).bin")
                                    let sigDestinationPath = sig.deletingLastPathComponent().appendingPathComponent("\(randomName).sig")
                                    do {
                                        try FileManager.default.moveItem(at: bin, to: binDestinationPath)
                                        try FileManager.default.moveItem(at: sig, to: sigDestinationPath)
                                    } catch {
                        
                                    }
                                    
                                    completion( ExtractedKeys(bin: binDestinationPath, sig: sigDestinationPath) )
                                    return
                                }
                            }
                            // If it falls through here this zip didn't not contain the export files we expect
                            completion(nil)
                            return
                        }
                    }) { (fileOutputURL) in
                        let lastComponent = fileOutputURL.lastPathComponent
                        outFilesMap[lastComponent] = fileOutputURL
                    }
        }
        catch {
            completion(nil)
            return
        }
    }
    // The URL passed to the completion is the local URL of the downloaded diagnosis key file
    static func downloadDiagnosisKeyFile(at remoteURL: URL, completion: @escaping (Result<[URL], Error>) -> Void) {
        SMLAPI.FetchToCache(url: remoteURL) { (url, err) in
            if let url = url {
                self.extractKeysFromZip(url) { (extractedKeys) in
                    guard let keys = extractedKeys else {
                        // Error
                        completion(.failure(err ?? ServerError.generic))
                        return
                    }
                    let binURL = keys.bin
                    let sigURL = keys.sig
                    
                    completion(.success([binURL, sigURL]))
                    return
                }
            }
            else {
                completion(.failure(err ?? ServerError.generic))
                return
            }
        }
    }
    
    func deleteDiagnosisKeyFile(at localURLs: [URL]) throws {
        for localURL in localURLs {
            try FileManager.default.removeItem(at: localURL)
        }
    }
    
    func getExposureConfiguration(completion: (Result<ENExposureConfiguration, Error>) -> Void) {
        let dataFromServer = """
        {"minimumRiskScore":1,
        "attenuationDurationThresholds":[55, 63],
        "attenuationLevelValues":[0, 0, 1, 1, 1, 1, 1, 1],
        "daysSinceLastExposureLevelValues":[1, 1, 1, 1, 1, 1, 1, 1],
        "durationLevelValues":[0, 1, 1, 1, 1, 1, 1, 1],
        "transmissionRiskLevelValues":[1, 1, 1, 1, 1, 1, 1, 1]}
        """.data(using: .utf8)!
        
        do {
            let codableExposureConfiguration = try JSONDecoder().decode(CodableExposureConfiguration.self, from: dataFromServer)
            let exposureConfiguration = ENExposureConfiguration()
            exposureConfiguration.minimumRiskScore = codableExposureConfiguration.minimumRiskScore
            exposureConfiguration.attenuationLevelValues = codableExposureConfiguration.attenuationLevelValues as [NSNumber]
            exposureConfiguration.daysSinceLastExposureLevelValues = codableExposureConfiguration.daysSinceLastExposureLevelValues as [NSNumber]
            exposureConfiguration.durationLevelValues = codableExposureConfiguration.durationLevelValues as [NSNumber]
            exposureConfiguration.transmissionRiskLevelValues = codableExposureConfiguration.transmissionRiskLevelValues as [NSNumber]
            exposureConfiguration.metadata = ["attenuationDurationThresholds": codableExposureConfiguration.attenuationDurationThresholds]
            completion(.success(exposureConfiguration))
        } catch {
            completion(.failure(error))
        }
    }
    
    func verifyUniqueTestIdentifier(_ identifier: String, completion: @escaping (Result<String, Error>) -> Void) {
        SMLAPI.SubmitValidationCodeToVA(code: identifier) { (success, httpStatusCode, token) in
            if(success) {
                if let token = token {
                    completion(.success(token))
                    return;
                }
                else {
                    completion(.failure(ServerError.invalidPIN))
                    return;
                }
            }
            else {
                if(SMLConfig.AcceptAllTestIdentifiers) {
                    let developmentToken = MockData.haValidationMockToken
                    completion(.success(developmentToken))
                    return;
                }
                else {
                    completion(.failure(ServerError.invalidPIN))
                }
            }
        }
    }
}
