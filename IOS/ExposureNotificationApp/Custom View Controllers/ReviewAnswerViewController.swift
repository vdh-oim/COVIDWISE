//
//  ReviewAnswerViewController.swift
//  ExposureNotificationApp
//
//  Created by Shaik Mudassir on 25/06/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import Foundation

class ReviewViewController: BrandViewController {
           
   
    @IBOutlet weak var buttonConfirm: iButton? {
        didSet {
            guard let button = buttonConfirm else { return }
            button.setTitle(NSLocalizedString("SHARE_POSITIVE_RESULT", comment: "Header").uppercased(), for: .normal)
            button.didTouchUpInside = { sender in
                print("Confirm Action Here")
            }
        }
    }
    @IBOutlet weak var mainStack: UIStackView!
    
    override init?(with coder: NSCoder) {
        super.init(with: coder)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        loadInputs()
    }
    private func loadInputs() {
        
        view.backgroundColor = UIColor.systemGroupedBackground
        title = NSLocalizedString("VERIFICATION_REVIEW_TITLE", comment: "Header")
//        title = "Before you get started"
        let titleStack = BeforeYouStartedStack(with: NSLocalizedString("VERIFICATION_REVIEW_TEXT", comment: "Header"),
                                                      font: UIFont(name: "Roboto-Medium", size: 20.0),
                                                      textAlignment: .left,
                                                      image: #imageLiteral(resourceName: "list"))
        mainStack.addArrangedSubview(titleStack)
    }
    
}
