//
//  Util.swift
//  ExposureNotificationApp
//
//

import Foundation
import JGProgressHUD

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
}

func randomString(minLength: Int, maxLength: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    var randLength = minLength;
    if(maxLength > minLength) {
        randLength = Int.random(in: minLength ..< maxLength)
    }
    return String((0..<randLength).map{ _ in letters.randomElement()! })
}

func numberOfDaysSinceToday(date: Date?) -> Int {
    if (date != nil) {
        return Calendar.current.dateComponents([.day], from: date!, to: Date()).day!
    } else {
        return -1
    }
}

func daysSinceLastExposureMessage() -> NSMutableAttributedString? {
    let daysSinceLastExposure = numberOfDaysSinceToday(date: LocalStore.shared.dateOfPositiveExposure!)
    var daysSinceLastExposureString = NSMutableAttributedString(string: String(daysSinceLastExposure))
    if (daysSinceLastExposure == 0 ) {
        daysSinceLastExposureString = NSMutableAttributedString(string: NSLocalizedString("TODAY", comment: "Text"))
    } else if (daysSinceLastExposure == 1) {
         let text = NSMutableAttributedString(string: NSLocalizedString("1_DAY_AGO", comment: "Text"))
                   text.replaceCharacters(in: (text.string as NSString).range(of: "%@"),
                                          with: String(daysSinceLastExposure))
        daysSinceLastExposureString = text
    } else {
        let text = NSMutableAttributedString(string: NSLocalizedString("N_DAYS_AGO", comment: "Text"))
        text.replaceCharacters(in: (text.string as NSString).range(of: "%@"),
                               with: String(daysSinceLastExposure))
        daysSinceLastExposureString = text
    }
    return daysSinceLastExposureString
}

func makeProgressHUD(text: String, inView view: UIView) -> JGProgressHUD {
    let hud = JGProgressHUD(style: .dark)
    hud.textLabel.text = text
    hud.show(in: view)
    return hud
}
func makeErrorHUD(text: String, inView view: UIView) -> JGProgressHUD {
    let hud = JGProgressHUD(style: .dark)
    hud.indicatorView = JGProgressHUDErrorIndicatorView()
    hud.textLabel.text = text
    hud.show(in: view)
    return hud
}

//MARK: -
func DLog<T>(message: T, function: String = #function){
    #if DEBUG
    print("\(function): \(message)")
    #endif
}
func applyDynamicType(textStyle:UIFont.TextStyle, font:UIFont) -> UIFont {
    let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
    return fontMetrics.scaledFont(for: font)
}
extension UIColor {
    convenience init(alpha: CGFloat = 1.0) { 
        let hexaString = "#00245d"
        let hexString: String = hexaString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        if (hexString.hasPrefix("#")) {
            let str = CharacterSet(charactersIn: "#")
            scanner.charactersToBeSkipped = str
        }
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
}

extension UIImage {
    func colorImage(with color: UIColor) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        UIGraphicsBeginImageContext(self.size)
        let contextRef = UIGraphicsGetCurrentContext()

        contextRef?.translateBy(x: 0, y: self.size.height)
        contextRef?.scaleBy(x: 1.0, y: -1.0)
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)

        contextRef?.setBlendMode(CGBlendMode.normal)
        contextRef?.draw(cgImage, in: rect)
        contextRef?.setBlendMode(CGBlendMode.sourceIn)
        color.setFill()
        contextRef?.fill(rect)

        let coloredImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return coloredImage
    }
}

extension Date {
    // Convert UTC to local time
    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
}
