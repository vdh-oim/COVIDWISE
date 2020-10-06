//
//  FinishedViewController.swift
//  ExposureNotificationApp
//
//

import UIKit
import Foundation

class FinishedViewController: BrandViewController {
    @IBOutlet weak var viBottomHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var mainStack: UIStackView!
    private var testResult: MutableTestResult!

    init?(with coder: NSCoder, testResult: MutableTestResult) {
        self.testResult = testResult
        super.init(with: coder)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        loadInputs()
    }
    @IBOutlet weak var labelTitle: UILabel? {
        didSet {
            guard let label = labelTitle else { return }
           label.text =  testResult.isShared ? NSLocalizedString("VERIFICATION_SHARED_TITLE", comment: "Title") : NSLocalizedString("VERIFICATION_NOT_SHARED_TITLE", comment: "Title")
        }
    }
    @IBOutlet weak var buttonConfirm: iButton? {
        didSet {
            guard let button = buttonConfirm else { return }
            button.setTitle(NSLocalizedString("DONE", comment: "Button").uppercased(), for: .normal)
            button.backgroundColor = themeDarkGreen
            button.didTouchUpInside = { sender in
                self.navigationController?.popToRootViewController(animated: false)
            }
        }
    }
    private func loadInputs() {
        
        view.backgroundColor = UIColor.systemGroupedBackground
        labelTitle?.text =  testResult.isShared ? NSLocalizedString("VERIFICATION_SHARED_TITLE", comment: "Title") : NSLocalizedString("VERIFICATION_NOT_SHARED_TITLE", comment: "Title")
                
        let titleStack = StepStack(with: LabelDetails(title: NSLocalizedString("VERIFICATION_SHARED_HEADER", comment: "Header"),
                                                      fontType: BrandFont.title,
                                                      textAlignment: .left),
                                   imageDetails: ImageDetails(image: #imageLiteral(resourceName: "clipboardCheck")), noTint: true) 
        mainStack.addArrangedSubview(titleStack)
        
        let descriptionStack = StepStack(with: LabelDetails(title: NSLocalizedString("VERIFICATION_SHARED_TEXT", comment: "Text"),
                                                                          fontType: BrandFont.subtitle2,
                                                                          textAlignment: .left))
        mainStack.addArrangedSubview(descriptionStack)
        
        if UIDevice().userInterfaceIdiom == .phone && (UIScreen.main.bounds.height == 812 || UIScreen.main.bounds.height == 896 ){
            viBottomHeightConstraint.constant = 83
        }
    }
    
}
