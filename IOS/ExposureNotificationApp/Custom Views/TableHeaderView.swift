/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A custom table view header.
*/

import UIKit

let cardShadow = CardShadow(with: 4.0, size: CGSize(width: 0, height: 2), opecity: 0.2, color: .black)
let themeColor = UIColor(red: 69.0/255.0, green: 39.0/255.0, blue: 245.0/255.0, alpha: 1)
let themeGreen = UIColor(red: 0, green: 187.0/255.0, blue: 18.0/255.0, alpha: 1)
let themeDarkGreen = UIColor(red: 42.0/255.0, green: 132.0/255.0, blue: 69.0/255.0, alpha: 1)

class TableHeaderView: UITableViewHeaderFooterView {
    
    var headerText: String? {
        get {
            headerLabel.text
        }
        set {
            headerLabel.text = newValue
        }
    }
    
    var text: String? {
        get {
            label.text
        }
        set {
            label.text = newValue
        }
    }
    var attributedText: NSAttributedString? {
        didSet {
            label.attributedText = attributedText
        }
    }
    
    var buttonText: String? {
        get {
            button.title(for: .normal)
        }
        set {
            button.setTitle(newValue, for: .normal)
            button.isHidden = buttonText == nil
        }
    }
    
    var buttonAction: (() -> Void)?
    var labelTapAction: (() -> Void)?
    let headerImage = UIImageView()
    let headerLabel = UILabel()
    let label = UILabel()
    let button = Button(type: .custom)
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        headerImage.image = UIImage(named: "handTick")?.withRenderingMode(.alwaysTemplate)
        headerImage.tintColor = UIColor(alpha:1.0 )
        headerImage.contentMode = .scaleAspectFit

        headerLabel.numberOfLines = 0
        headerLabel.textAlignment = .left
        headerLabel.textColor = BrandFont.title.color
        headerLabel.font = applyDynamicType(textStyle: .headline, font: BrandFont.title.font)
        headerLabel.adjustsFontForContentSizeCategory = true
        
        
        let headerStack = UIStackView(arrangedSubviews: [headerImage, headerLabel])
        headerStack.axis = .horizontal
        headerStack.distribution = .fill
        headerStack.alignment = .center
        headerStack.spacing = 10
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        label.numberOfLines = 0
        label.textColor = BrandFont.title.color
        label.font = applyDynamicType(textStyle: .headline, font: BrandFont.subtitle.font)
        label.adjustsFontForContentSizeCategory = true
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target:self, action: #selector(tapLabel(gesture:))))
        
        button.isHidden = true
        button.setTitleColor(BrandFont.description.color, for: .normal)
        button.addTarget(self, action: #selector(buttonTouchUpInside), for: .touchUpInside)
        button.titleLabel!.font = applyDynamicType(textStyle: .headline, font: BrandFont.description.font)
        
        let stackView = UIStackView(arrangedSubviews: [headerStack, label, button])
        stackView.axis = .vertical
        stackView.spacing = 12.0
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false

        preservesSuperviewLayoutMargins = true
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor, constant: -5.0),
            stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor, constant: 5.0),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20.0),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20.0)
        ])
        
        NSLayoutConstraint.activate([
            headerImage.widthAnchor.constraint(equalToConstant: 30),
            headerImage.heightAnchor.constraint(equalToConstant: 30),
            headerLabel.widthAnchor.constraint(equalToConstant: 200),
            headerLabel.trailingAnchor.constraint(equalTo: stackView.layoutMarginsGuide.trailingAnchor),
        ])
        
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 10)

        stackView.addBackground(color: .white, cardShadow: cardShadow)
        layoutView(with: .black, cardShadow: cardShadow)

        contentView.bringSubviewToFront(stackView)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func buttonTouchUpInside() {
        buttonAction?()
    }
    
    func setCustomButton(color: UIColor) {
        button.setTitleColor(color, for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .left
    }
    
    @IBAction func tapLabel(gesture: UITapGestureRecognizer){
        let termsRange = (text as! NSString).range(of: NSLocalizedString("LEARN_MORE_LINK", comment: "Text"))

        if gesture.didTapAttributedTextInLabel(label: label, inRange: termsRange) {
            labelTapAction?()
        } else {
        }
    }
}

extension UITapGestureRecognizer {

    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        
        guard let attributedString = label.attributedText else
        {
            return false
            
        }
        
        //IMPORTANT label correct font for NSTextStorage needed
        let mutableAttribString = NSMutableAttributedString(attributedString: attributedString)
        mutableAttribString.addAttributes(
            [NSAttributedString.Key.font: label.font ?? UIFont.smallSystemFontSize],
            range: NSRange(location: 0, length: attributedString.length)
        )
        
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: mutableAttribString)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        //let textContainerOffset = CGPointMake((labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
                                              //(labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y);
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)

        //let locationOfTouchInTextContainer = CGPointMake(locationOfTouchInLabel.x - textContainerOffset.x,
                                                        // locationOfTouchInLabel.y - textContainerOffset.y);
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return NSLocationInRange(indexOfCharacter, targetRange)
    }

}

extension TableHeaderView {
    
    private func layoutView(with color: UIColor, cardShadow: CardShadow) {
        
        let containerView = UIView()

        // set the shadow of the view's layer
        layer.backgroundColor = UIColor.clear.cgColor
        layer.shadowColor = color.cgColor
        layer.shadowOffset = cardShadow.size
        layer.shadowOpacity = cardShadow.opacity
        layer.shadowRadius = cardShadow.radius
              
        // set the cornerRadius of the containerView's layer
        containerView.layer.cornerRadius = cardShadow.radius
        containerView.layer.masksToBounds = true
        containerView.isUserInteractionEnabled = false
        addSubview(containerView)
            
        // add constraints
        containerView.translatesAutoresizingMaskIntoConstraints = false
            
        // pin the containerView to the edges to the view
        containerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
    }
}

extension UIView {
    func addCardShadow(color: UIColor, cardShadow: CardShadow) {
        layer.cornerRadius = cardShadow.radius
              
        let shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cardShadow.radius)
        layer.masksToBounds = true
        layer.shadowColor = color.cgColor
        layer.shadowOffset = CGSize(width: cardShadow.size.width, height: cardShadow.size.height);
        layer.shadowOpacity = cardShadow.opacity
        layer.shadowPath = shadowPath.cgPath
    }
}
extension UIStackView {
    func addBackground(color: UIColor, cardShadow: CardShadow) {
        let subView = UIView(frame: bounds)
        subView.backgroundColor = color
        subView.addCardShadow(color: color, cardShadow: cardShadow)
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
    }
    func addBackground(color: UIColor) {
        let subView = UIView(frame: bounds)
        subView.backgroundColor = color
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
    }
}



struct CardShadow {
    var radius: CGFloat
    var size: CGSize
    var opacity: Float
    var color: UIColor
    
    init(with radius: CGFloat, size: CGSize, opecity: Float, color: UIColor) {
        self.radius = radius
        self.size = size
        self.color = color
        self.opacity = opecity
    }
}
