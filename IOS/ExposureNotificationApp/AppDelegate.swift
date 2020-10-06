/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The application delegate.
*/

import UIKit
import ExposureNotification
import BackgroundTasks
import UserNotifications
//import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    static let backgroundTaskIdentifier = Bundle.main.bundleIdentifier! + ".exposure-notification"
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        //FirebaseApp.configure()
        if LocalStore.shared.testDeviceName == "Test Device" {
            // Uninitialized device name
            LocalStore.shared.testDeviceName = randomString(minLength: 5, maxLength: 5).uppercased()
        }
        
        
        ApplyAppearance()
        UNUserNotificationCenter.current().delegate = self
        if(SMLConfig.SendTestPushOnLaunch) {
            SMLNotifications.sendLikelyExposedNotification()
        }
        if(SMLConfig.SendDelayedPushOnLaunch) {
            SMLNotifications.sendLikelyExposedNotificationAfter3S()
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: AppDelegate.backgroundTaskIdentifier, using: .main) { task in
            
            // Notify the user if bluetooth is off
            ExposureManager.shared.showBluetoothOffUserNotificationIfNeeded()            
            // Schedule follow-up key pushes up to 24-hours
            if let pendingPushOfKeys = LocalStore.shared.pendingDiagnosisPushRequest {
                let timeSinceInitialPush = Date().timeIntervalSince(pendingPushOfKeys.timeOfInitialRequest)
                if !(timeSinceInitialPush > 24 * 60 * 60) {
                    ExposureManager.shared.scheduleGetAndPostDiagnosisKeys(testResult: pendingPushOfKeys.testResult, skipRescheduling: true) { (err) in
                        if let err = err {
                            
                        }
                        else {
                
                        }
                    }
                }
                else {
                   
                }
            }
            else {
               
            }
            
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
        scheduleBackgroundTaskIfNeeded()
        application.showDarkMode(false)
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier,
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let tabBarController = scene.windows.first?.rootViewController as? UITabBarController {
            tabBarController.selectedIndex = 0
        }
    }
    
    func scheduleBackgroundTaskIfNeeded() {
        let taskRequest = BGProcessingTaskRequest(identifier: AppDelegate.backgroundTaskIdentifier)
        taskRequest.requiresNetworkConnectivity = true
        //taskRequest.earliestBeginDate = Date(timeIntervalSinceNow: 1 * 60)
        do {
            try BGTaskScheduler.shared.submit(taskRequest)
        } catch {
        }
    }
    //Background Issue
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        BackgroundSession.shared.savedCompletionHandler = completionHandler
    }
}


extension UIApplication {
    
    ///*! USED TO IGNORE THE DARKMODE */
    func showDarkMode(_ iBool: Bool) {
        guard !iBool else { return }
        
        self.windows.forEach { window in
            if #available(iOS 13.0, *) {
                window.overrideUserInterfaceStyle = .light
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    
}
