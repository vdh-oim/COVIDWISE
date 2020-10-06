//
//  SMLNotifications.swift
//  ExposureNotificationApp
//
//

import UserNotifications
import Foundation

class SMLNotifications {
    static let EXPOSED_MSG = NSLocalizedString("USER_NOTIFICATION_TEXT", comment: "Text")
    static let EXPOSED_TITLE =  NSLocalizedString("USER_NOTIFICATION_TITLE", comment: "Title")
    static func send(notificationRequest: UNNotificationRequest) {
        UNUserNotificationCenter.current().add(notificationRequest) { (err) in
            if let err = err {
            }
        }
    }
    static func sendLikelyExposedNotificationAfter3S() {
        let content = UNMutableNotificationContent()
        content.body = EXPOSED_MSG
        content.title = EXPOSED_TITLE
        
        let req = UNNotificationRequest(identifier: "covid-19-exposure-notification", content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false))
        SMLNotifications.send(notificationRequest: req)
    }
    
    static func sendLikelyExposedNotification() {
        if let dateLastSentExposureNotification = LocalStore.shared.dateLastSentExposureNotification {
            // Check if the date of last notification sent is greater than 23 hours
            if (Date().timeIntervalSince(dateLastSentExposureNotification) < 23 * 60 * 60) {
                
            } else {
                sendLikelyExposedNotificationAndStoreNotfifcationDate()
            }
        } else {
            sendLikelyExposedNotificationAndStoreNotfifcationDate()
        }
    }
    
    static func sendLikelyExposedNotificationAndStoreNotfifcationDate() {
        _ = SMLNotifications.createNotificationRequest(title: EXPOSED_TITLE, message: EXPOSED_MSG, identifier: "covid-19-exposure-notification", automaticallySend: true)
        LocalStore.shared.dateLastSentExposureNotification = Date()
    }
    
    static func sendTestNotification() {
        let req = SMLNotifications.createNotificationRequest(title: "Title", message: "Message goes here.\nNewline!", identifier: "rand", automaticallySend: false)
        UNUserNotificationCenter.current().add(req) { (err) in
            if let err = err {
            }
        }
    }
    static func createNotificationRequest(title: String, message: String, identifier: String = "random-notification-identifier-\(randomString(minLength: 6, maxLength: 6))", automaticallySend: Bool = true) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.body = message
        content.title = title
        
        let req = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        if(automaticallySend) {
            UNUserNotificationCenter.current().add(req) { (err) in
                if let err = err {
                }
            }
        }
        return req
    }
}
