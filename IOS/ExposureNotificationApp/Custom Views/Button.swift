/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A button with a customized appearance.
*/

import UIKit

class Button: UIButton {
    
    var contentSizeCategoryObserver: NSObjectProtocol!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        titleLabel?.adjustsFontForContentSizeCategory = true
        contentSizeCategoryObserver = NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification,
                                                                             object: nil, queue: .main) { [unowned self] notification in
            self.setNeedsLayout()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(contentSizeCategoryObserver!)
    }
}

class PlatterButton: Button {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.layer.cornerRadius = 13.0
        self.layer.cornerCurve = .continuous
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = max(size.height, 50.0)
        return size
    }
    
    override func tintColorDidChange() {
        self.setNeedsLayout()
    }
    
    var isProminent = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if isProminent {
            self.backgroundColor = themeDarkGreen
            self.setTitleColor(.white, for: .normal)
        } else {
            self.backgroundColor = .secondarySystemFill
            self.setTitleColor(UIColor(alpha: 1.0), for: .normal) 
        }
    }
}
