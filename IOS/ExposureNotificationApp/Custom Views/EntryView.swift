/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view for entering a unique identifier.
*/

import UIKit

class EntryStackView: UIStackView {
    var activate: (() -> Void)?
    override func accessibilityActivate() -> Bool {
        activate?()
        return true
    }
}

class EntryView: UIView, UITextFieldDelegate {
    
    let numberOfDigits = 6
    
    var textFields = [UITextField]()
    var mainStackView: EntryStackView?
    
    var text: String {
        textFields.map { $0.text ?? "" }.joined()
    }
    
    var textDidChange: (() -> Void)?
    
    func combinedAccessibilityTextFieldValues() -> String {
        var string = ""
        for textField in textFields {
            string += textField.accessibilityValue ?? ""
        }
        return string
    }
 
    init() {
        super.init(frame: .zero)
        
        let label = UILabel()
        label.text = NSLocalizedString("VERIFICATION_IDENTIFIER_ENTRY_LABEL", comment: "Label")
        label.font = BrandFont.subtitle.font
        label.textColor = themeDarkGreen
        label.numberOfLines = 0
        label.textAlignment = .left
        label.adjustsFontForContentSizeCategory = true
        
        for _ in 0..<numberOfDigits {
            let textField = UITextField()
            textField.adjustsFontForContentSizeCategory = true
            textField.font = UIFont.preferredFont(forTextStyle: .largeTitle)
            textField.textAlignment = .center
            textField.keyboardType = .numberPad
            textField.borderStyle = .none
            textField.backgroundColor = .tertiarySystemBackground
//            textField.layer.cornerRadius = 8.0
//            textField.layer.cornerCurve = .continuous
            textField.delegate = self
            textField.isAccessibilityElement = false
            textField.underlined(color: themeDarkGreen)
            textFields.append(textField)
        }
        
        textFields[0].becomeFirstResponder()
        let entryStackView = UIStackView(arrangedSubviews: textFields)
        entryStackView.axis = .horizontal
        entryStackView.distribution = .fillEqually
        entryStackView.spacing = 5.0

        let stackView = EntryStackView(arrangedSubviews: [label, entryStackView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 5.0
        stackView.accessibilityLabel = label.accessibilityLabel
        stackView.accessibilityTraits = textFields[0].accessibilityTraits
        stackView.isAccessibilityElement = true
        
        let textField1 = textFields[0]
        stackView.activate = {
            textField1.becomeFirstResponder()
            textField1.selectAll(nil)
        }

        self.mainStackView = stackView
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            entryStackView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            entryStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80.0),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.selectAll(nil)
        textField.underlined(color: themeDarkGreen) 
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        textField.text = string
        let index = textFields.firstIndex(of: textField)!
        if string.isEmpty {
            if index >= 1  {
                textFields[index - 1].becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
        } else {
            if index < numberOfDigits - 1 {
                textFields[index + 1].becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
        }
        textDidChange?()
        mainStackView?.accessibilityValue = combinedAccessibilityTextFieldValues()
        return false
    }
    
    func clearAllTextFields() {
        for textField in self.textFields {
            textField.text = ""
        }
    }
}

extension UITextField {
    
    func underlined(color: UIColor) {
        layer.sublayers?.removeAll()
        
        let border = CALayer()
        let width = CGFloat(2.0)
        border.borderColor = color.cgColor
        border.frame = CGRect(x: -5, y: -5, width: 100, height: 70)
        border.borderWidth = width
        layer.addSublayer(border)
        layer.masksToBounds = true
    }

}
