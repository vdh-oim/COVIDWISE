
# Production checklist
 - Ensure Code Signing Entitlements are set to 'ExposureNotificationApp/Production.entitlements' - Under the Build Settings tab on XCode
 - Visit SMLConfig.swift and validate the following values:
```
// Testing (Set to false for production)
static let AcceptAllTestIdentifiers = false
static let FirebaseNamePromptEnabled = false
static let SendTestPushOnLaunch = false
static let SendDelayedPushOnLaunch = false
static let pinVerificationTimeoutDemoEnabled = false
```
 - Also in SMLConfig.swift, validate all production URLs

```NetRequest.Endpoints.KEYS_INDEX```

```NetRequest.Endpoints.UPLOAD_KEYS```

```SMLConfig.VirtualAgentURL```

```SMLConfig.PINVerificationURL```

Use the production distribution profile `VA Exposure Notification Distribution`


## Build Notes

First, clone the repo:

```
git clone git@github.com:springml-code/exposure-notifications-ios.git VACovid
```

Next, cd in to the repo and install the missing Pods directory

```
cd VACovid
pod install
```

Note: If this step fails you may need to install or otherwise update your Cocoapods installation. Follow guidance here for installation: https://guides.cocoapods.org/using/getting-started.html






```

```


# ORIGINAL APPLE README BELOW LEFT INTACT FOR REFERENCE

# Building an App to Notify Users of COVID-19 Exposure

Inform people when they may have been exposed to COVID-19.

## Overview

This code project uses the ExposureNotification framework to build a sample app that lets people know when they have come into contact with someone who meets a set of criteria for a case of COVID-19. When using the project as a reference for designing a notification app, you can define the criteria for how the framework determines whether the risk is high enough to report to the user.

The sample app includes code to simulate server responses. When building an exposure notification app based on this project, create a server environment to provide diagnosis keys and exposure criteria, and add code to your app to communicate with this server. If the app you build operates in a country that authenticates medical tests for COVID-19, you may need to include additional network code to communicate with those authentication services.

For more information on the architecture and security of the ExposureNotification service, see [Privacy-Preserving Contact Tracing](https://www.apple.com/covid19/contacttracing/).

## Configure the Sample Code Project
Before you run the sample code project in Xcode, make sure:
* Your iOS device is running iOS 13.5 or later.
* You are running Xcode 11.5 or later.
* You configure the project with a provisioning profile that includes the Exposure Notification entitlement. To get permission to use this entitlement, see [Exposure Notification Entitlement Request](https://developer.apple.com/contact/request/exposure-notification-entitlement).

## Authorize Exposure Notifications

Users must explicitly authorize an app to participate in exposure notification. The [`ENManager`][ENManager] class provides information on the user's authorization status and requests authorization. The app creates a singleton `ENManager` object, using its own class to manage the object's lifetime.

``` swift
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
                    // No error handling for attempts to enable on launch
                }
            }
        }
    }
    
    deinit {
        manager.invalidate()
    }
```

Each time the app launches, it checks to see if the user has authorized notifications. If the user hasn't authorized the app, it displays a user interface asking the user to authorize the service.

``` swift
func sceneDidBecomeActive(_ scene: UIScene) {
    let rootViewController = window!.rootViewController!
    if !LocalStore.shared.isOnboarded && rootViewController.presentedViewController == nil {
        rootViewController.performSegue(withIdentifier: "ShowOnboarding", sender: nil)
    }
}
```

The `OnboardingViewController` class provides the complete workflow to display the permission request. The app calls the [`setExposureNotificationEnabled(_:completionHandler:)`][setExposureNotificationEnabled] method on the `ENManager` singleton.

``` swift
static func enableExposureNotifications(from viewController: UIViewController) {
    ExposureManager.shared.manager.setExposureNotificationEnabled(true) { error in
        NotificationCenter.default.post(name: ExposureManager.authorizationStatusChangeNotification, object: nil)
        if let error = error as? ENError, error.code == .notAuthorized {
            viewController.show(RecommendExposureNotificationsSettingsViewController.make(), sender: nil)
        } else if let error = error {
            showError(error, from: viewController)
        } else {
            (UIApplication.shared.delegate as! AppDelegate).scheduleBackgroundTaskIfNeeded()
            enablePushNotifications(from: viewController)
        }
    }
}
```

When the framework calls the completion handler, the app checks to see whether the user authorized exposure notifications. If the user hasn't done so, the app displays a different screen alerting the user to the importance of opting into the behavior, and offers the user a second opportunity to authorize the app. The user can still decline. 

## Store User Data Locally

The app stores information about test results and high-risk exposures in the user defaults directory. The local data is private and stays on the device.

A custom property wrapper transforms data between its native format and a JSON-formatted equivalent, reads and writes data in the user defaults dictionary, and posts notifications to the app when local data changes. The `LocalStore` class manages the user's private data, defined as a series of properties that all use this property wrapper.

``` swift
class LocalStore {
    
    static let shared = LocalStore()
    
    @Persisted(userDefaultsKey: "isOnboarded", notificationName: .init("LocalStoreIsOnboardedDidChange"), defaultValue: false)
    var isOnboarded: Bool
    
    @Persisted(userDefaultsKey: "nextDiagnosisKeyFileIndex", notificationName: .init("LocalStoreNextDiagnosisKeyFileIndexDidChange"), defaultValue: 0)
    var nextDiagnosisKeyFileIndex: Int
    
    @Persisted(userDefaultsKey: "exposures", notificationName: .init("LocalStoreExposuresDidChange"), defaultValue: [])
    var exposures: [Exposure]
    
    @Persisted(userDefaultsKey: "dateLastPerformedExposureDetection",
               notificationName: .init("LocalStoreDateLastPerformedExposureDetectionDidChange"), defaultValue: nil)
    var dateLastPerformedExposureDetection: Date?
    
    @Persisted(userDefaultsKey: "exposureDetectionErrorLocalizedDescription", notificationName:
        .init("LocalStoreExposureDetectionErrorLocalizedDescriptionDidChange"), defaultValue: nil)
    var exposureDetectionErrorLocalizedDescription: String?
    
    @Persisted(userDefaultsKey: "testResults", notificationName: .init("LocalStoreTestResultsDidChange"), defaultValue: [:])
    var testResults: [UUID: TestResult]
}
```

The app defines its own data structures for any data it persists. For example, a test result records the date the user took the test, and whether the user shared this data with the server. This information is used to populate the user interface.

``` swift
struct TestResult: Codable {
    var id: UUID                // A unique identifier for this test result
    var isAdded: Bool           // Whether the user completed the add positive diagnosis flow for this test result
    var dateAdministered: Date  // The date the test was administered
    var isShared: Bool          // Whether diagnosis keys were shared with the Health Authority for the purpose of notifying others
}
```

## Share Diagnosis Keys with the Server

A user with a diagnosis for COVID-19 can upload *diagnosis keys* to the server. Each instance of the app periodically downloads diagnosis keys to search the device’s private interaction data for matching interactions.

This project simulates a remote server with which the app communicates. There is a single `Server` object in the app that stores the received diagnosis keys and provides them on demand. The sample server does not partition the data by region. It maintains a single list of keys, and provides the entire list upon request. 

``` swift
// Replace this class with your own class that communicates with your server.
class Server {
    
    static let shared = Server()
    
    // For testing purposes, this object stores all of the TEKs it receives locally on device
    // In a real implementation, these would be stored on a remote server
    @Persisted(userDefaultsKey: "diagnosisKeys", notificationName: .init("ServerDiagnosisKeysDidChange"), defaultValue: [])
    var diagnosisKeys: [CodableDiagnosisKey]
```

As with the local store, this local server stores the data in JSON format, using the same `Persisted` property wrapper.

## Ask Users to Share COVID-19 Indicators

The sample app demonstrates a strategy in which a recognized medical authority tested the user and found positive COVID-19 indicators. The sample app provides a way for users to enter an authentication code, but doesn't submit this data to an authentication service, so all codes automatically pass. 

When the user provides information about a positive test result, the app records the test result in the local store and asks the user to share it. To share the result, the app needs to get a list of diagnosis keys and send the list to the server. To get the keys, the app calls the singleton `ENManager` object's [`getDiagnosisKeys(completionHandler:)`][getDiagnosisKeysWithCompletionHandler] method, as shown in the code below.

``` swift
func getAndPostDiagnosisKeys(testResult: TestResult, completion: @escaping (Error?) -> Void) {
    manager.getDiagnosisKeys { temporaryExposureKeys, error in
        if let error = error {
            completion(error)
        } else {
            // In this sample app, transmissionRiskLevel isn't set for any of the diagnosis keys. However, it is at this point that an app could
            // use information accumulated in testResult to determine a transmissionRiskLevel for each diagnosis key.
            Server.shared.postDiagnosisKeys(temporaryExposureKeys!) { error in
                completion(error)
            }
        }
    }
}
```

Each time the app calls this method, the user must authorize the transaction. The framework then returns the list of keys to the app. The app sends those keys as-is to the server and then updates the test record to indicate that it was shared.

The sample app's server implementation appends the keys onto a list it maintains, skipping any keys that are already there. It stores the keys sequentially so that the app can request just the keys it hasn't received before.

``` swift
func postDiagnosisKeys(_ diagnosisKeys: [ENTemporaryExposureKey], completion: (Error?) -> Void) {
    
    // Convert keys to something that can be encoded to JSON and upload them.
    let codableDiagnosisKeys = diagnosisKeys.compactMap { diagnosisKey -> CodableDiagnosisKey? in
        return CodableDiagnosisKey(keyData: diagnosisKey.keyData,
                                   rollingPeriod: diagnosisKey.rollingPeriod,
                                   rollingStartNumber: diagnosisKey.rollingStartNumber,
                                   transmissionRiskLevel: diagnosisKey.transmissionRiskLevel)
    }
    
    // In a real implementation, these keys would be uploaded with URLSession instead of being saved here.
    // Your server needs to handle de-duplicating keys.
    for codableDiagnosisKey in codableDiagnosisKeys where !self.diagnosisKeys.contains(codableDiagnosisKey) {
        self.diagnosisKeys.append(codableDiagnosisKey)
    }
    completion(nil)
}
```

## Create a Background Task to Check for Exposure

The app uses a background task to periodically check whether the user may have been exposed to an individual with COVID-19. The app's `Info.plist` file declares a background task named `com.example.apple-samplecode.ExposureNotificationSampleApp.exposure-notification`. The BackgroundTask framework detects apps that contain the Exposure Notification entitlement and a background task that ends in `exposure-notification`. The operating system automatically launches these apps when they aren't running and guarantees them more background time to ensure that the app can test and report results promptly.

The app delegate schedules the background task:

``` swift
func scheduleBackgroundTaskIfNeeded() {
    guard ENManager.authorizationStatus == .authorized else { return }
    let taskRequest = BGProcessingTaskRequest(identifier: AppDelegate.backgroundTaskIdentifier)
    taskRequest.requiresNetworkConnectivity = true
    do {
        try BGTaskScheduler.shared.submit(taskRequest)
    } catch {
        print("Unable to schedule background task: \(error)")
    }
}
```

First, the background task provides a handler in case it runs out of time. Then it calls the app's `detectExposures` method to test for exposures. Finally, it schedules the next time the system should execute the background task.

``` swift
BGTaskScheduler.shared.register(forTaskWithIdentifier: AppDelegate.backgroundTaskIdentifier, using: .main) { task in
    
    // Notify the user if bluetooth is off
    ExposureManager.shared.showBluetoothOffUserNotificationIfNeeded()
    
    // Perform the exposure detection
    let progress = ExposureManager.shared.detectExposures { success in
        task.setTaskCompleted(success: success)
    }
    
    // Handle running out of time
    task.expirationHandler = {
        progress.cancel()
        LocalStore.shared.exposureDetectionErrorLocalizedDescription = NSLocalizedString("BACKGROUND_TIMEOUT", comment: "Error")
    }
    
    // Schedule the next background task
    self.scheduleBackgroundTaskIfNeeded()
}
```

The remaining sections describe how the app obtains the set of diagnosis keys and submits them to the framework for evaluation.


## Download Diagnosis Keys

The app downloads diagnosis keys from the server to pass to the framework, starting with the first key the app hasn't downloaded before. This design ensures that the app checks each diagnosis key only once on any given device.

The app needs to provide signed key files to the framework. The app asks the server for the URLs of any key files that the server generated after the last file that the app checked. After receiving the URLs from the server, the app uses a dispatch group to download the files to the device. 

``` swift
let nextDiagnosisKeyFileIndex = LocalStore.shared.nextDiagnosisKeyFileIndex

Server.shared.getDiagnosisKeyFileURLs(startingAt: nextDiagnosisKeyFileIndex) { result in
    
    let dispatchGroup = DispatchGroup()
    var localURLResults = [Result<[URL], Error>]()
    
    switch result {
    case let .success(remoteURLs):
        for remoteURL in remoteURLs {
            dispatchGroup.enter()
            Server.shared.downloadDiagnosisKeyFile(at: remoteURL) { result in
                localURLResults.append(result)
                dispatchGroup.leave()
            }
        }
        
    case let .failure(error):
        finish(.failure(error))
    }
```

Finally, the app creates an array of the local URLs for the downloaded files.

``` swift
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
```

## Configure Criteria to Estimate Risk

The framework will compare locally saved interaction data against the diagnosis keys provided by the app. When the framework finds a match, it calculates a risk score for that interaction based on a number of different factors, such as when the interaction took place and how long the devices were in proximity to each other.

To provide specific guidance to the framework about how risk should be evaluated, the app creates an [`ENExposureConfiguration`][ENExposureConfiguration] object. The app requests the criteria from the `Server` object, which creates and returns an `ENExposureConfiguration` object as shown below. The sample configuration has placeholder data that evaluates any interaction as risky, so the framework returns all interactions that match the diagnostic keys.

``` swift
func getExposureConfiguration(completion: (Result<ENExposureConfiguration, Error>) -> Void) {
    
    let dataFromServer = """
    {"minimumRiskScore":0,
    "attenuationDurationThresholds":[50, 70],
    "attenuationLevelValues":[1, 2, 3, 4, 5, 6, 7, 8],
    "daysSinceLastExposureLevelValues":[1, 2, 3, 4, 5, 6, 7, 8],
    "durationLevelValues":[1, 2, 3, 4, 5, 6, 7, 8],
    "transmissionRiskLevelValues":[1, 2, 3, 4, 5, 6, 7, 8]}
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
```

## Submit Diagnosis Keys to the Framework 

After downloading the key files, the app performs the search for exposures using a series of asynchronous steps. First, the app requests the criteria from the server, which calls into the code shown in the Configure Criteria to Estimate Risk section above. Then the app calls the `ENManager` objects's [`detectExposures(configuration:diagnosisKeyURLs:completionHandler:)`][detectExposures] method, passing the criteria and the URLs for the downloaded key files. This method returns a summary of the search results.

Next, the app calls the `ENManager` object's [`getExposureInfo(summary:userExplanation:completionHandler:)`][getExposureInfo] method to get details for all exposures events that met the risk criteria. This method returns an array of [`ENExposureInfo`][ENExposureInfo] objects. The app maps the exposure information to its own structure so that it can save the data to the app's local store.

``` swift
Server.shared.getExposureConfiguration { result in
    switch result {
    case let .success(configuration):
        ExposureManager.shared.manager.detectExposures(configuration: configuration, diagnosisKeyURLs: localURLs) { summary, error in
            if let error = error {
                finish(.failure(error))
                return
            }
            let userExplanation = NSLocalizedString("USER_NOTIFICATION_EXPLANATION", comment: "User notification")
            ExposureManager.shared.manager.getExposureInfo(summary: summary!, userExplanation: userExplanation) { exposures, error in
                    if let error = error {
                        finish(.failure(error))
                        return
                    }
                    let newExposures = exposures!.map { exposure in
                        Exposure(date: exposure.date,
                                 duration: exposure.duration,
                                 totalRiskScore: exposure.totalRiskScore,
                                 transmissionRiskLevel: exposure.transmissionRiskLevel)
                    }
                    finish(.success((newExposures, nextDiagnosisKeyFileIndex + localURLs.count)))
            }
        }
        
    case let .failure(error):
        finish(.failure(error))
    }
}
```

Finally, the app calls its `finish` method to complete the search. The `finish` method updates the local store with the new data, including any exposures, the date and time the app executed the search, and the index for the key file to check next time.


[ENManager]: https://developer.apple.com/documentation/exposurenotification/enmanager
[getDiagnosisKeysWithCompletionHandler]: https://developer.apple.com/documentation/exposurenotification/enmanager/3583725-getdiagnosiskeys
[setExposureNotificationEnabled]: https://developer.apple.com/documentation/exposurenotification/enmanager/3583729-setexposurenotificationenabled
[ENExposureConfiguration]: https://developer.apple.com/documentation/exposurenotification/enexposureconfiguration
[detectExposures]: https://developer.apple.com/documentation/exposurenotification/enmanager/3586331-detectexposures
[getExposureInfo]: https://developer.apple.com/documentation/exposurenotification/enmanager/3586332-getexposureinfo
[ENExposureInfo]: https://developer.apple.com/documentation/exposurenotification/enexposureinfo
