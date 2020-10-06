/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Code that displays a UIAlert for a view controller or opens Settings.
*/

import UIKit

func alert(_ title: String, _ msg: String, from viewController: UIViewController) {
    let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Button"), style: .default))
    viewController.present(alert, animated: true, completion: nil)
}

/*func showBluetoothSettingsAlert(_ title: String,
           _ msg: String,
           from viewController: UIViewController,
           done: @escaping ((UIAlertAction) -> Void)
) {
    let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Open Settings App", style: .default, handler: done))
    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Button"), style: .destructive))
    viewController.present(alert, animated: true, completion: nil)
}*/

func showError(_ error: Error, from viewController: UIViewController) {
    let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: "Title"), message: error.localizedDescription, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Button"), style: .cancel))
    viewController.present(alert, animated: true, completion: nil)
}

func openSettings(from viewController: UIViewController) {
    viewController.view.window?.windowScene?.open(URL(string: UIApplication.openSettingsURLString)!, options: nil, completionHandler: nil)
}

func setupNavigationBar(navigationItem: UINavigationItem, title: String) {
    navigationItem.title = ""
    let barButtonItem = UIBarButtonItem(
          title: title,
          style: UIBarButtonItem.Style.plain,
          target: nil,
          action: nil
    );
    barButtonItem.tintColor = UIColor.white
    navigationItem.leftBarButtonItem = barButtonItem
    barButtonItem.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "Roboto-Medium", size: 20)!], for: [])    //barButtonTem.titleTextAttributes(for: [NSAttributedString.Key.font: UIFont(name: "Roboto-Medium", size: 20)!,
    //NSAttributedString.Key.foregroundColor: UIColor.white])
}
