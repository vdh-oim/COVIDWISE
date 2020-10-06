//
//  Styles.swift
//  ExposureNotificationApp
//
//

import Foundation
import UIKit

func ApplyAppearance() {
    UITableView.appearance().backgroundColor = UIColor(named: "mainBackground")
    UITableViewCell.appearance().backgroundColor = UIColor(named: "mainBackground")
    UITextView.appearance().backgroundColor = UIColor(named: "mainBackground")
    UITextField.appearance().backgroundColor = UIColor(named: "mainBackground")
    UITabBar.appearance().backgroundColor = UIColor(named: "tabbarBackground")
//    UIView.appearance().tintColor = UIColor(named: "link")
    UINavigationBar.appearance().backgroundColor = UIColor(named: "liftedBackground")
    
}

extension UILabel {
    @objc var substituteFontName : String {
        get { return self.font.fontName }
        set {
            if self.font.fontName.range(of:"Medium") == nil {
                self.font = UIFont(name: newValue, size: self.font.pointSize)
            }
        }
    }

    @objc var substituteFontNameBold : String {
        get { return self.font.fontName }
        set {
            if self.font.fontName.range(of:"Medium") != nil {
                self.font = UIFont(name: newValue, size: self.font.pointSize)
            }
        }
    }
}
