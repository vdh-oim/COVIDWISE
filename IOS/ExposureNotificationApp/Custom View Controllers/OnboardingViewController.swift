/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controllers used in the onboarding workflow.
*/

import UIKit
import ExposureNotification

class OnboardingViewController: StepNavigationController {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        pushViewController(WelcomeViewController.make(), animated: false)
    }
    
    init?<CustomItem: Hashable>(rootViewController: CustomStepViewController<CustomItem>, coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        pushViewController(rootViewController, animated: false)
    }
    
    class WelcomeViewController: StepViewController {
        override var step: Step {
            Step(
                title: NSLocalizedString("WELCOME_TITLE", comment: "Title"),
                text: NSLocalizedString("WELCOME_TEXT", comment: "Text"),
                buttons: [Step.Button(title: NSLocalizedString("GET_STARTED", comment: "Button"), isProminent: true, action: {
                    self.show(EnableExposureNotificationsViewController.make(), sender: nil)
                })]
            )
        }
    }
    
    class EnableExposureNotificationsViewController: StepViewController {
        
        override var step: Step {
            let learnMoreURL = SMLConfig.LearnMoreLink
            let text = NSMutableAttributedString(string: NSLocalizedString("ENABLE_EXPOSURE_TEXT", comment: "Text"), attributes: Step.bodyTextAttributes)
            text.replaceCharacters(in: (text.string as NSString).range(of: "%@"),
                                   with: NSAttributedString(string: NSLocalizedString("LEARN_MORE_LINK", comment: "Link"),
                                                            attributes: Step.linkTextAttributes(learnMoreURL)))
            return Step(
                title: NSLocalizedString("ENABLE_EXPOSURE_TITLE", comment: "Title"),
                text: text ,
                customView: nil,
                isModal: false,
                buttons: [
                    Step.Button(title: NSLocalizedString("CONTINUE", comment: "Button"), isProminent: true, action: {
                        enableExposureNotifications(from: self)
                    }),
                    Step.Button(title: NSLocalizedString("DONT_ENABLE", comment: "Button"), action: {
                        self.show(RecommendExposureNotificationsViewController.make(), sender: nil)
                    })
                ]
            )
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
        }
    }
    
    class RecommendExposureNotificationsViewController: StepViewController {
        override var step: Step {
            Step(
                hidesNavigationBackButton: true,
                title: NSLocalizedString("RECOMMEND_EXPOSURE_TITLE", comment: "Title"),
                text: NSLocalizedString("RECOMMEND_EXPOSURE_TEXT", comment: "Text"),
                buttons: [
                    Step.Button(title: NSLocalizedString("ENABLE", comment: "Button"), isProminent: true, action: {
                        enableExposureNotifications(from: self)
                    }),
                    Step.Button(title: NSLocalizedString("DONT_ENABLE", comment: "Button"), action: {
                        (self.presentingViewController as! UITabBarController).selectedIndex = 0
                        finishOnboarding(from: self)
                    })
                ]
            )
        }
    }
    
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
    
    class RecommendExposureNotificationsSettingsViewController: StepViewController {
        override var step: Step {
            Step(
                hidesNavigationBackButton: true,
                title: NSLocalizedString("RECOMMEND_EXPOSURE_TITLE", comment: "Title"),
                text: NSLocalizedString("RECOMMEND_EXPOSURE_TEXT", comment: "Text"),
                buttons: [
                    Step.Button(title: NSLocalizedString("GO_TO_SETTINGS", comment: "Button"), isProminent: true, action: {
                        openSettings(from: self)
                    }),
                    Step.Button(title: NSLocalizedString("DONT_ENABLE", comment: "Button"), action: {
                        finishOnboarding(from: self)
                    })
                ]
            )
        }
    }
    
    static func enablePushNotifications(from viewController: UIViewController) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    viewController.show(NotifyingOthersViewController.make(independent: false), sender: nil)
                } else {
                    viewController.show(RecommendPushNotificationsViewController.make(), sender: nil)
                }
            }
        }
    }
    
    class RecommendPushNotificationsViewController: StepViewController {
        override var step: Step {
            Step(
                hidesNavigationBackButton: true,
                title: NSLocalizedString("RECOMMEND_PUSH_TITLE", comment: "Title"),
                text: NSLocalizedString("RECOMMEND_PUSH_TEXT", comment: "Text"),
                buttons: [
                    Step.Button(title: NSLocalizedString("GO_TO_SETTINGS", comment: "Button"), isProminent: true, action: {
                        openSettings(from: self)
                    }),
                    Step.Button(title: NSLocalizedString("NOT_NOW", comment: "Button"), action: {
                        self.show(NotifyingOthersViewController.make(independent: false), sender: nil)
                    })
                ]
            )
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            let notification = UIScene.didActivateNotification
            let windowScene = view.window!.windowScene!
            observers.append(NotificationCenter.default.addObserver(forName: notification, object: windowScene, queue: nil) {
                [unowned self] notification in
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    if settings.authorizationStatus == .authorized {
                        DispatchQueue.main.async {
                            self.show(NotifyingOthersViewController.make(independent: false), sender: nil)
                        }
                    }
                }
            })
        }
    }
    
    class NotifyingOthersViewController: ValueStepViewController<Bool, Never> {
        
        var independent: Bool { value } // Whether this view controller is being shown outside the normal onboarding flow
        
        static func make(independent: Bool) -> Self {
            return make(value: independent)
        }
        
        let text = NSLocalizedString("VERIFICATION_IDENTIFIER_TEXT", comment: "Text")
        
        override var step: Step {
            let text = NSMutableAttributedString(string: NSLocalizedString("NOTIFYING_OTHERS_TEXT", comment: "Text"),
                                                 attributes: Step.bodyTextAttributes)
            return Step(
                hidesNavigationBackButton: true,
                rightBarButton: independent ? .init(item: .done) {
                    self.dismiss(animated: true, completion: nil)
                } : nil,
                title: NSLocalizedString("NOTIFYING_OTHERS_TITLE", comment: "Title"),
                text: text,
                isModal: false,
                buttons: independent ? [] : [Step.Button(title: NSLocalizedString("DONE", comment: "Button"), isProminent: true, action: {
                    finishOnboarding(from: self)
                })]
            )
        }
    }
    
    static func finishOnboarding(from viewController: UIViewController) {
        LocalStore.shared.isOnboarded = true
        viewController.dismiss(animated: true, completion: nil)
    }
}
