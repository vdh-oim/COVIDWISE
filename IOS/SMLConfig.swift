//
//  SMLConfig.swift
//  ExposureNotificationApp
//
//

import Foundation
import UIKit

struct SMLConfig {
    static let PINVerificationTestURL = URL(string: "TODO")!
    static let PINVerificationURL = URL(string: "TODO")!
    static let PrivacyPolicyURL = URL(string: "TODO")!
    static let KEYS_BUCKET = "TODO"
    static let KEYS_INDEX = URL(string: "TODO")!
    static let UPLOAD_KEYS = URL(string: "TODO")!
    static let POST_MESSAGES = URL(string: "TODO")!
    static var VirtualAgentURL: String {
        get {
            return NSLocalizedString("VIRTUAL_AGENT_URL", comment: "VirtualAgentURL")
        }
    }
    static let LearnMoreLink = URL(string: "TODO")!
    // Testing (Set to false for production)
    static let AcceptAllTestIdentifiers = false
    //static let FirebaseNamePromptEnabled = false
    static let SendTestPushOnLaunch = false
    static let SendDelayedPushOnLaunch = false
    static let CertPinningDisabled = false
    static let pinVerificationTimeoutDemoEnabled = false
    static let AllowMultipleExposureDetectionCallsPerDay = false
    static let ShowDeveloperTabBarItem = false
    static let virtualTabIndex = 2
    // Every time the background task executes (around every 4 hours),
    // the app downloads a series of zip files from the server to submit
    // to the Exposure Notification APIs. There is a hard limit of 15 zips
    // that can be processed per day. This limit is enforced by iOS, and we
    // can not alter it. To avoid triggering this limit, we specify a maximum
    // number of zips (Diagnoses Key Files) that should be downloaded at one
    // time / during a single background task.
    static let maximumNumberOfDiagnosisKeysToDownloadPerFourHours = 14
    // Analytics
    //static let FirebaseLoggingEnabled = true
    static let networkRequestTimeoutInSeconds = 300.0 // TODO: Change to 60 seconds or longer in production
    static let verboseNetworkLogging = true // TODO: Set to false in production
    static let downloadInterval = 12.0
}

extension NetRequest {
    // Configuration
    struct Endpoints {
        static let TEST_VERIFICATION =
        SMLConfig.pinVerificationTimeoutDemoEnabled
            ? SMLConfig.PINVerificationTestURL
            : SMLConfig.PINVerificationURL
    }
    struct Configuration {
        static let timeout = SMLConfig.networkRequestTimeoutInSeconds
        static let verbose = SMLConfig.verboseNetworkLogging
    }
}
