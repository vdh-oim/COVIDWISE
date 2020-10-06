//
//  iView.swift
//  ExposureNotificationApp
//
//


import UIKit

@IBDesignable public class iView: UIButton {
    
    @IBInspectable var setCardTransparency: Bool = false {
        didSet {
            guard setCardTransparency else { return }
            layer.cornerRadius = 2.0
            layer.shadowColor = UIColor.lightGray.cgColor
            layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
            layer.shadowRadius = 3.0
            layer.shadowOpacity = 0.9
            layer.masksToBounds = false
        }
    }
}
