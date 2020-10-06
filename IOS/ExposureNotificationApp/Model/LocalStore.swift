/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class that contains and manages locally stored app data.
*/

import Foundation
import ExposureNotification

struct Exposure: Codable {
    let date: Date
    let duration: TimeInterval
    let totalRiskScore: ENRiskScore
    let transmissionRiskLevel: ENRiskLevel
}

struct TestResult: Codable {
    var id: UUID                // A unique identifier for this test result
    var isAdded: Bool           // Whether the user completed the add positive diagnosis flow for this test result
    var dateAdministered: Date  // The date the test was administered
    var isShared: Bool          // Whether diagnosis keys were shared with the Health Authority for the purpose of notifying others
    var pinCode: String         // A PIN verifying its a legit result
}

struct MutableTestResult: Codable {
    var id: UUID                // A unique identifier for this test result
    var isAdded: Bool           // Whether the user completed the add positive diagnosis flow for this test result
    var dateAdministered: Date  // The date the test was administered
    var isShared: Bool          // Whether diagnosis keys were shared with the Health Authority for the purpose of notifying others
    var pinCode: String?         // A PIN verifying its a legit result
    func makeTestResult() -> TestResult? {
        guard let pinCode = pinCode else {
            return nil
        }
        return TestResult(id: id, isAdded: isAdded, dateAdministered: dateAdministered, isShared: isShared, pinCode: pinCode)
    }
}

@propertyWrapper
class Persisted<Value: Codable> {
    
    init(userDefaultsKey: String, notificationName: Notification.Name, defaultValue: Value) {
        self.userDefaultsKey = userDefaultsKey
        self.notificationName = notificationName
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            do {
                wrappedValue = try JSONDecoder().decode(Value.self, from: data)
            } catch {
                wrappedValue = defaultValue
            }
        } else {
            wrappedValue = defaultValue
        }
    }
    
    let userDefaultsKey: String
    let notificationName: Notification.Name
    
    var wrappedValue: Value {
        didSet {
            UserDefaults.standard.set(try! JSONEncoder().encode(wrappedValue), forKey: userDefaultsKey)
            NotificationCenter.default.post(name: notificationName, object: nil)
        }
    }
    
    var projectedValue: Persisted<Value> { self }
    
    func addObserver(using block: @escaping () -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: nil) { _ in
            block()
        }
    }
}

struct DiagnosisPushRequest: Decodable, Encodable {
    let testResult: TestResult
    let timeOfInitialRequest: Date
}

class LocalStore {
    
    static let shared = LocalStore()
    
    @Persisted(userDefaultsKey: "pendingDiagnosisPushRequest", notificationName: .init("pendingDiagnosisPushRequest"), defaultValue: nil)
    var pendingDiagnosisPushRequest: DiagnosisPushRequest?
    
    @Persisted(userDefaultsKey: "isOnboarded", notificationName: .init("LocalStoreIsOnboardedDidChange"), defaultValue: false)
    var isOnboarded: Bool
    
    @Persisted(userDefaultsKey: "testDeviceName", notificationName: .init("testDeviceName-_"), defaultValue: "Test Device")
    var testDeviceName: String
    
    @Persisted(userDefaultsKey: "nextDiagnosisKeyFileIndex", notificationName: .init("LocalStoreNextDiagnosisKeyFileIndexDidChange"), defaultValue: 0)
    var nextDiagnosisKeyFileIndex: Int
    
    @Persisted(userDefaultsKey: "exposures", notificationName: .init("LocalStoreExposuresDidChange"), defaultValue: [])
    var exposures: [Exposure]
    
    @Persisted(userDefaultsKey: "dateOfPositiveExposure-", notificationName: .init("dateOfPositiveExposureDidChange"), defaultValue: nil)
    var dateOfPositiveExposure: Date?
    
    @Persisted(userDefaultsKey: "dateLastPerformedExposureDetection",
               notificationName: .init("LocalStoreDateLastPerformedExposureDetectionDidChange"), defaultValue: nil)
    var dateLastPerformedExposureDetection: Date?
    
    @Persisted(userDefaultsKey: "dateLastSentExposureNotification",
               notificationName: .init("LocalStoreDateLastSentExposureNotificationDidChange"), defaultValue: nil)
    var dateLastSentExposureNotification: Date?
    
    @Persisted(userDefaultsKey: "exposureDetectionErrorLocalizedDescription", notificationName:
        .init("LocalStoreExposureDetectionErrorLocalizedDescriptionDidChange"), defaultValue: nil)
    var exposureDetectionErrorLocalizedDescription: String?
    
    @Persisted(userDefaultsKey: "testResults", notificationName: .init("LocalStoreTestResultsDidChange"), defaultValue: [:])
    var testResults: [UUID: MutableTestResult]
    
    @Persisted(userDefaultsKey: "pinFailedAttemptDates", notificationName: .init("PinFailedAttemptDates"), defaultValue: [])
    var pinFailedAttemptDates: [Date]
    
    func cleanOldPinAttempts() {
        let tenMinutesInSeconds: Double = 10 * 60
        // Remove any failure dates older than 10 minutes
        pinFailedAttemptDates = pinFailedAttemptDates.filter({ (testDate) -> Bool in
            let timeSinceFailure = Date().timeIntervalSince(testDate)
            if(timeSinceFailure > tenMinutesInSeconds) {
                return false
            }
            return true
        })
    }
    struct PinAttemptInfo {
        let remainingAttempts: Int
        let retryTimeString: String
    }
    let MaximumPinAttemptsWithinTenMinutes = 3
    func pinAttemptsRemaining() -> PinAttemptInfo {
        self.cleanOldPinAttempts()
        if pinFailedAttemptDates.count < 1 {
            return PinAttemptInfo(remainingAttempts: MaximumPinAttemptsWithinTenMinutes, retryTimeString: "P1")
        }
        let retryTimeString = NSLocalizedString("VERIFICATION_IDENTIFIER_RETRY_MESSAGE", comment: "Text")
        let latestAttempt = pinFailedAttemptDates[pinFailedAttemptDates.count - 1]
        let timeSinceLatestPINAttempt = NSDate().timeIntervalSince(latestAttempt)
        let minutes = Int(timeSinceLatestPINAttempt / 60.0)
        let remainingMinutes = 10 - minutes
        var timeRemainingStr = "\(remainingMinutes) \(NSLocalizedString("MINUTES", comment: "Text"))"
        if remainingMinutes <= 1 {
            timeRemainingStr = "1 \(NSLocalizedString("MINUTE", comment: "Text"))"
        }
        let retryText = String(format: retryTimeString, timeRemainingStr)
        
        return PinAttemptInfo(
            remainingAttempts: max(0, MaximumPinAttemptsWithinTenMinutes - pinFailedAttemptDates.count),
            retryTimeString: retryText
        )
    }
    
    func pinAttemptDidFail() {
        pinFailedAttemptDates.append(Date())
        if(pinFailedAttemptDates.count > MaximumPinAttemptsWithinTenMinutes) {
            let removedElement = pinFailedAttemptDates.remove(at: 0)
        }
        self.cleanOldPinAttempts()
    }
}
