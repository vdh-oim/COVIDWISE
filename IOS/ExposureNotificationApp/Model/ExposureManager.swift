/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class that manages a singleton ENManager object.
*/

import Foundation
import ExposureNotification
import UserNotifications
import JGProgressHUD

class ExposureManager {
    
    static let shared = ExposureManager()
    
    let manager = ENManager()
    
    init() {
        manager.activate { _ in
            // Ensure exposure notifications are enabled if the app is authorized. The app
            // could get into a state where it is authorized, but exposure
            // notifications are not enabled,  if the user initially denied Exposure Notifications
            // during onboarding, but then flipped on the "COVID-19 Exposure Notifications" switch
            // in Settings.
            if ENManager.authorizationStatus == .authorized && !self.manager.exposureNotificationEnabled {
                self.manager.setExposureNotificationEnabled(true) { _ in
                }
            }
        }
    }
    
    deinit {
        manager.invalidate()
    }
    
    static let authorizationStatusChangeNotification = Notification.Name("ExposureManagerAuthorizationStatusChangedNotification")
    
    var detectingExposures = false
    
    func detectExposures(completionHandler: @escaping ((Bool) -> Void)) -> Progress {
        // TODO: Ensure all code paths call completionHandler
        let progress = Progress()
        if(!SMLConfig.AllowMultipleExposureDetectionCallsPerDay) {
            let dayInSeconds = SMLConfig.downloadInterval * 60.0 * 60.0
            if let dateLastPerformedExposureDetection = LocalStore.shared.dateLastPerformedExposureDetection {
                if Date().timeIntervalSince(dateLastPerformedExposureDetection) < dayInSeconds {
                    completionHandler(false)
                    return progress
                }
            }
        }
        
        // Disallow concurrent exposure detection, because if allowed we might try to detect the same diagnosis keys more than once
        guard !detectingExposures else {
            completionHandler(false)
            return progress
        }
        detectingExposures = true
        
        var localURLs = [URL]()
        
        func finish(_ result: Result<([Exposure], Int), Error>) {
            
            try? Server.shared.deleteDiagnosisKeyFile(at: localURLs)
            
            let success: Bool
            if progress.isCancelled {
                success = false
            } else {
                switch result {
                case let .success((newExposures, nextDiagnosisKeyFileIndex)):
                    LocalStore.shared.nextDiagnosisKeyFileIndex = nextDiagnosisKeyFileIndex
                    LocalStore.shared.exposures.append(contentsOf: newExposures)
                    LocalStore.shared.exposures.sort { $0.date < $1.date }
                    LocalStore.shared.dateLastPerformedExposureDetection = Date()
                    LocalStore.shared.exposureDetectionErrorLocalizedDescription = nil
                    success = true
                case let .failure(error):
                    LocalStore.shared.exposureDetectionErrorLocalizedDescription = error.localizedDescription
                    // Consider posting a user notification that an error occured
                    success = false
                }
            }
            
            detectingExposures = false
            completionHandler(success)
        }
        let nextDiagnosisKeyFileIndex = LocalStore.shared.nextDiagnosisKeyFileIndex
        
        Server.shared.getDiagnosisKeyFileURLs(startingAt: nextDiagnosisKeyFileIndex) { result in
            let maxURLSToProcess = SMLConfig.maximumNumberOfDiagnosisKeysToDownloadPerFourHours
            let dispatchGroup = DispatchGroup()
            var localURLResults = [Result<[URL], Error>]()
            switch result {
            case let .success(remoteURLs):
                var lastNURLs = remoteURLs
                if remoteURLs.count > maxURLSToProcess {
                    // Never process more than 15 urls at once, due to quota
                    lastNURLs = []
                    for i in 0..<maxURLSToProcess {
                        lastNURLs.append( remoteURLs[remoteURLs.count - i - 1] )
                    }
                }
                for remoteURL in lastNURLs {
                    dispatchGroup.enter()
                    Server.downloadDiagnosisKeyFile(at: remoteURL) { result in
                        localURLResults.append(result)
                        dispatchGroup.leave()
                    }
                }
                
            case let .failure(error):
                finish(.failure(error))
            }
            dispatchGroup.notify(queue: .main) {
                for result in localURLResults {
                    switch result {
                    case let .success(urls):
                        localURLs.append(contentsOf: urls)
                    case let .failure(error):
                        finish(.failure(error))
                        return
                    }
                }
                Server.shared.getExposureConfiguration { result in
                    switch result {
                    case let .success(configuration):
                        if let metadata = configuration.metadata {
                        }
                        else {
                        }
                        // Gets a summary of multiple exposures
                        ExposureManager.shared.manager.detectExposures(configuration: configuration, diagnosisKeyURLs: localURLs) { summary, error in
                            if let error = error {
                                // Treat rate limiter errors as successes with no new keys
                                if let error = error as? ENError, error.code == .rateLimited {
                                    finish(.success(([],0)))
                                    return;
                                }
                                finish(.failure(error))
                                return;
                            }
                            if let summary = summary {
                                let duration_close = summary.attenuationDurations[0]
                                let duration_medium = summary.attenuationDurations[1]
                                //let duration_far = summary.attenuationDurations[2]
                                let risk_duration = duration_close.doubleValue + duration_medium.doubleValue * 0.5 // Measured in seconds
                                if(risk_duration >= 15.0/*15 minutes*/ * 60.0) {
                                    // This is an exposure
                                    SMLNotifications.sendLikelyExposedNotification()
                                    
                                    // Sets the last exposure for use in the exposures tab view
                                    let timeIntervalSinceLastExposure = Double(summary.daysSinceLastExposure) * 24.0 * 60.0 * 60.0
                                    let lastExposure = Date().advanced(by: -timeIntervalSinceLastExposure)
                                    LocalStore.shared.dateOfPositiveExposure = lastExposure
                                    postLog("I_CW_91001")
                                    let emptyExposures: [Exposure] = []
                                    finish(.success((emptyExposures, nextDiagnosisKeyFileIndex + localURLs.count)))
                                }
                                else {
                                    if risk_duration > 0.0{
                                        postLog("I_CW_91009_\(Int(risk_duration))")
                                    }
                                    self.resetDateOfLastExposure()
                                    finish(.success(([], 0))) // TODO: Think about this more, is this a failure?
                                }
                            }
                            else {
                                self.resetDateOfLastExposure()
                                finish(.success(([], 0))) // TODO: Think about this more, is this a failure?
                            }
                        }
                        
                    case let .failure(error):
                        finish(.failure(error))
                    }
                }
            }
        }
        return progress
    }
    
    func resetDateOfLastExposure() {
        if let dateOfPositiveExposure = LocalStore.shared.dateOfPositiveExposure {
            let daysSinceLastExposure = numberOfDaysSinceToday(date: dateOfPositiveExposure)
            
            if (daysSinceLastExposure > 14) {
                LocalStore.shared.dateOfPositiveExposure = nil
            }
        } else {
            
        }
    }
    
    func scheduleGetAndPostDiagnosisKeys(
            testResult: TestResult,
            skipRescheduling: Bool = false,
            completion: @escaping (Error?) -> Void
    ) {
        /*let delayedPushRequest = DiagnosisPushRequest(
            testResult: testResult,
            timeOfInitialRequest: Date()
        )
        if(!skipRescheduling) {
            LocalStore.shared.pendingDiagnosisPushRequest = delayedPushRequest
        }
        else {
        }*/
        self.getAndPostDiagnosisKeys(testResult: testResult, completion: completion)
    }
    
    // TODO: Use TestResult
    private func getAndPostDiagnosisKeys(testResult: TestResult, completion: @escaping (Error?) -> Void) {
        manager.getDiagnosisKeys { temporaryExposureKeys, error in
            if let error = error {
                postLog("I_CW_ERROR in download keys \(error)")
                completion(error)
            } else {
                // In this sample app, transmissionRiskLevel isn't set for any of the diagnosis keys. However, it is at this point that an app could
                // use information accumulated in testResult to determine a transmissionRiskLevel for each diagnosis key.
                if temporaryExposureKeys!.count < 1 {
                    completion(ExposureManagerError.noKeysToPost)
                    return;
                }
                SMLAPI.PostKeys(keys: temporaryExposureKeys!, pinToken: testResult.pinCode) { (success, msg) in
                    if(!success) {
                        completion(ExposureManagerError.postKeysError(msg ?? "Key Post Error 78512"))
                    }
                    else {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    public enum ExposureManagerError: Error {
        case postKeysError(String)
        case noKeysToPost
    }
    
    enum FeatureError: Error {
        case deprecated
    }
    // Includes today's key, requires com.apple.developer.exposure-notification-test entitlement
    func getAndPostTestDiagnosisKeys(completion: @escaping (Error?) -> Void) {
        completion(FeatureError.deprecated)
    }
    
    func showBluetoothOffUserNotificationIfNeeded() {
        let identifier = "bluetooth-off"
        if ENManager.authorizationStatus == .authorized && manager.exposureNotificationStatus == .bluetoothOff {
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("USER_NOTIFICATION_BLUETOOTH_OFF_TITLE", comment: "User notification title")
            content.body = NSLocalizedString("USER_NOTIFICATION_BLUETOOTH_OFF_BODY", comment: "User notification")
            content.sound = .default
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                    }
                }
            }
        } else {
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
        }
    }
}
