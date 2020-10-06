//
//  TestIdentifierViewController.swift
//  ExposureNotificationApp
//
//

import UIKit
import Foundation
import JGProgressHUD


enum BrandFont {
    case title, subtitle, description, subtitle2, subtitle3
    
    var font: UIFont {
        switch self {
        case .title:
            return UIFont(name: "Roboto-Medium", size: 20.0) ?? UIFont.systemFont(ofSize: 20.0)
        case .subtitle, .subtitle2:
            return UIFont(name: "Roboto-Regular", size: 16.0) ?? UIFont.systemFont(ofSize: 16.0)
        case .subtitle3:
            return UIFont(name: "Roboto-Bold", size: 16.0) ?? UIFont.systemFont(ofSize: 16.0)
        case .description:
            return UIFont(name: "Roboto-Regular", size: 14.0) ?? UIFont.systemFont(ofSize: 14.0)
        }
    }
    var color: UIColor {
        switch self {
        case .title, .subtitle2, .subtitle3:
            return .black
        case .subtitle, .description:
            return UIColor(red: 117.0/255.0, green: 117.0/255.0, blue: 117.0/255.0, alpha: 1)
        }
    }
}


class TestIdentifierViewController: BrandViewController {
               
    fileprivate var entryView: EntryView!
    private var testResult: MutableTestResult!

    @IBOutlet weak var viBottomHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainStack: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!

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
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        if UIDevice().userInterfaceIdiom == .phone && UIScreen.main.bounds.height == 568 {
           NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
           NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        }
        
    }
    @objc func keyboardWillHide(notification: NSNotification) {
        scrollView.contentOffset = .zero
    }
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrameValue = notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue else {
            return
        }
        self.view.layoutIfNeeded()
        let keyboardFrame = view.convert(keyboardFrameValue.cgRectValue, from: nil)
        scrollView.contentOffset = CGPoint(x:0, y:keyboardFrame.size.height)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if UIDevice().userInterfaceIdiom == .phone && UIScreen.main.bounds.height == 568 {
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        self.title = NSLocalizedString("VERIFICATION_IDENTIFIER_TITLE", comment: "Header")
    }
    
    @IBOutlet weak var buttonNext: iButton? {
        didSet {
            guard let button = buttonNext else { return }
            button.setTitle(NSLocalizedString("NEXT", comment: "Button").uppercased(), for: .normal)
            button.backgroundColor = themeDarkGreen
            button.didTouchUpInside = { sender in
                self.callValidateOTP()
            }
        }
    }
                
    private func callValidateOTP() {
        
        self.validateOTP { (success, message) in
            if success {
                postLog("I_CW_91002")
                self.testResult.pinCode = message
                self.performSegue(withIdentifier: "showReviewAnswer", sender: nil)
            } else {
                LocalStore.shared.pinAttemptDidFail()
                self.entryView.clearAllTextFields()
                let alertController = UIAlertController(title: NSLocalizedString("VERIFICATION_IDENTIFIER_INVALID",
                                                                                 comment: "Alert title"),
                                                        message: nil,
                                                        preferredStyle: .alert)
                alertController.addAction(.init(title: NSLocalizedString("OK", comment: "Button"),
                                                style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                postLog("I_CW_ERROR in pin verification \(message)")
            }
        }
            
    }
        
    private func validateOTP(completion: ((_ success: Bool, _ message: String) -> ())?) {
        // Display a HUD
        let hud = makeProgressHUD(text: "Verifying", inView: self.view)
        let attempsRemainingInfo = LocalStore.shared.pinAttemptsRemaining()
            
        if attempsRemainingInfo.remainingAttempts < 1 {
            DispatchQueue.main.async {
                //hud.dismiss()
                hud.textLabel.text = attempsRemainingInfo.retryTimeString
                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                hud.dismiss(afterDelay: 2.5, animated: true)
            }
            return
        }
        Server.shared.verifyUniqueTestIdentifier(self.entryView.text) { result in
            DispatchQueue.main.async {
                hud.dismiss(animated: true)
                switch result {
                case let .success(pinCode):
                    completion?(true, pinCode)
                case let .failure(error):
                    completion?(false, error.localizedDescription)
                }
            }
        }
    }
        
    @IBSegueAction func showReviewAnswer(_ coder: NSCoder) -> ReviewViewController? {       
        return ReviewViewController(with: coder, testResult: testResult)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    private func loadInputs() {
        entryView = EntryView()
            
        self.view.backgroundColor = UIColor.systemGroupedBackground
        entryView.textDidChange = { [unowned self] in
            self.updateButtons()
        }
        
        let titleStack = StepStack(with: LabelDetails(title: NSLocalizedString("VERIFICATION_IDENTIFIER_HEADER", comment: "Header"),
                                                                  fontType: BrandFont.title,
                                                                  textAlignment: .left),
                                               imageDetails: ImageDetails(image: #imageLiteral(resourceName: "chatQuestion")))
        mainStack.addArrangedSubview(titleStack)
            
        let subtitleStack = StepStack(with: LabelDetails(title: NSLocalizedString("VERIFICATION_IDENTIFIER_TEXT", comment: "Text"),
                                                                     fontType: BrandFont.subtitle2,
                                                                     textAlignment: .left))
        mainStack.addArrangedSubview(subtitleStack)
        mainStack.addArrangedSubview(entryView)

        let subtitle1Stack = StepStack(with: LabelDetails(title: NSLocalizedString("VERIFICATION_IDENTIFIER_TEXT1", comment: "Text"),
                                                                     fontType: BrandFont.subtitle3,
                                                                     textAlignment: .left))
        mainStack.addArrangedSubview(subtitle1Stack)
        mainStack.addArrangedSubview(entryView)

        let subtitle2Stack = StepStack(with: LabelDetails(title: NSLocalizedString("VERIFICATION_IDENTIFIER_TEXT2", comment: "Text"),
                                                                      fontType: BrandFont.description,
                                                                      textAlignment: .left))
        mainStack.addArrangedSubview(subtitle2Stack)
        updateButtons()
        
        if UIDevice().userInterfaceIdiom == .phone && (UIScreen.main.bounds.height == 812 || UIScreen.main.bounds.height == 896 ){
            viBottomHeightConstraint.constant = 83
        }
    }
    private func updateButtons() {
        DispatchQueue.main.async {
            self.buttonNext?.isEnabled = (self.entryView.text.count == 6)
        }
    }
    
    
}
