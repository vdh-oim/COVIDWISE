/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The scene delegate.
*/

import UIKit
//import FirebaseDatabase

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UITextFieldDelegate {

    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let window = UIWindow(windowScene: scene as! UIWindowScene)
        self.window = window
        window.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        
        // Remove Developer Tab if it is production
        if (!SMLConfig.ShowDeveloperTabBarItem) {
            (window.rootViewController as! UITabBarController).viewControllers?.remove(at: 3)
        }

        (window.rootViewController as! UITabBarController).selectedIndex = 0
        window.makeKeyAndVisible()
    }
    var _textField: UITextField?
    var _label: UILabel?
    func sceneDidBecomeActive(_ scene: UIScene) {
        let rootViewController = window!.rootViewController!
        if  ((LocalStore.shared.testDeviceName == "Test Device" || LocalStore.shared.testDeviceName == "") && rootViewController.presentedViewController == nil) {
            let textField = UITextField(frame: rootViewController.view.frame)
            _textField = textField
            textField.backgroundColor = UIColor.white
            textField.textColor = UIColor.black
            rootViewController.view.addSubview(textField)
            textField.delegate = self
            
            let label = UILabel(frame: rootViewController.view.frame)
            label.frame = label.frame.offsetBy(dx: 0, dy: -120)
            label.text = "Please specify a device name\n(For example: iphone-x)\n"
            label.numberOfLines = 3
            label.textColor = UIColor.darkGray
            _label = label
            rootViewController.view.addSubview(label)
            
            textField.becomeFirstResponder()
        }
        else if !LocalStore.shared.isOnboarded && rootViewController.presentedViewController == nil {
            rootViewController.performSegue(withIdentifier: "ShowOnboarding", sender: nil)
        }
    }
    
    // For the UITextFieldDelegate that names test devices
    // TODO: Remove this and the protocol
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            if text.count > 0 {
                LocalStore.shared.testDeviceName = text
                if let tf = _textField {
                    tf.removeFromSuperview()
                }
                if let l = _label {
                    l.removeFromSuperview()
                }
                exit(0)
            }
        }
        return true
    }
}
