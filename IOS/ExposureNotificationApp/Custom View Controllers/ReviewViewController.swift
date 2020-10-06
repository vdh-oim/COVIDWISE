//
//  ReviewAnswerViewController.swift
//  ExposureNotificationApp
//
//

import UIKit
import Foundation
import JGProgressHUD
import ExposureNotification


class ReviewViewController: BrandViewController {
    @IBOutlet weak var viBottomHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var mainStack: UIStackView!
    private var testResult: MutableTestResult!

    init?(with coder: NSCoder, testResult: MutableTestResult) {
        let pin = testResult.pinCode
        self.testResult = testResult
        LocalStore.shared.testResults[testResult.id]!.pinCode = pin
        super.init(with: coder)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        loadInputs()
    }
    @IBOutlet weak var buttonConfirm: iButton? {
        didSet {
            guard let button = buttonConfirm else { return }
            button.setTitle(NSLocalizedString("TEST_RESULT_SHARE", comment: "Button").uppercased(), for: .normal)
            button.backgroundColor = themeDarkGreen
            button.didTouchUpInside = { sender in
                self.callReviewPinCode()
            }
        }
    }
    @IBSegueAction func showFinished(_ coder: NSCoder) -> FinishedViewController? {
        return FinishedViewController(with: coder, testResult: testResult)
    }
       

    private func callReviewPinCode() {
        guard let testResult = self.testResult.makeTestResult() else {
            let hud = JGProgressHUD(style: .dark)
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.textLabel.text = "Not a valid test result"
            hud.show(in: self.view)
            hud.dismiss(afterDelay: 2.5, animated: true)
            return
        }
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Processing"
        hud.show(in: self.view)
        ExposureManager.shared.scheduleGetAndPostDiagnosisKeys(testResult: testResult) { error in
            DispatchQueue.main.async {
                hud.dismiss()
                if let error = error as? ENError, error.code == .notAuthorized {
                    postLog("I_CW_ERROR in upload keys \(error)")
                    self.saveAndDismiss()
                } else if let error = error {
                    if let emError = error as? ExposureManager.ExposureManagerError {
                        switch emError {
                        case .noKeysToPost:
                            self.showErrorAlert(NSLocalizedString("NO_KEYS_TITLE", comment: "Title"), NSLocalizedString("NO_KEYS_TEXT", comment: "Text"))
                            return;
                        case .postKeysError(let str):
                            self.showErrorAlert("Error", str)
                            return;
                        }
                    }
                    postLog("I_CW_ERROR in upload keys \(error)")
                    showError(error, from: self)
                    self.saveAndFinish()
                } else {
                    self.saveAndFinish()
                    self.updateSharedResults()
                }
            }
        }
    }
    
    private func updateSharedResults() {
        self.testResult.isShared = true
        LocalStore.shared.testResults[testResult.id] = self.testResult
    }
    
    private  func saveAndFinish() {
        DispatchQueue.main.async {
            self.testResult.isAdded = true
            LocalStore.shared.testResults[self.testResult.id] = self.testResult
            self.performSegue(withIdentifier: "showFinished", sender: nil)
        }
    }
    
    func showErrorAlert(_ title: String, _ msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: NSLocalizedString("OK", comment: "Button"), style: .default) { action in
                self.saveAndDismiss()
            }
        )
        self.present(alert, animated: true, completion: nil)
    }
    private  func saveAndDismiss() {
        self.testResult.isAdded = true
        LocalStore.shared.testResults[self.testResult.id] = self.testResult
        self.navigationController?.popToRootViewController(animated: false)
    }
    
    private func loadInputs() {
        
        view.backgroundColor = UIColor.systemGroupedBackground
        title = NSLocalizedString("VERIFICATION_REVIEW_TITLE", comment: "Header")
//        title = "Review your answers"

        let titleStack = StepStack(with: LabelDetails(title: NSLocalizedString("VERIFICATION_REVIEW_TEXT", comment: "Header"),
                                                                  fontType: BrandFont.title,
                                                                  textAlignment: .left),
                                               imageDetails: ImageDetails(image: #imageLiteral(resourceName: "list")))
        mainStack.addArrangedSubview(titleStack)
            
        let subTitle = StepStack(with: LabelDetails(title: NSLocalizedString("TEST_RESULT_DIAGNOSIS", comment: "Header").uppercased(),
                                                                fontType: BrandFont.subtitle,
                                                                textAlignment: .left))
        subTitle.addBackground(color: .white)

        let label1 = UILabel()
        let inputStack = UIStackView(arrangedSubviews: [subTitle, label1])
        inputStack.axis = .vertical
        inputStack.alignment = .fill
        inputStack.distribution = .fill
        inputStack.spacing =  2.0
        inputStack.contentMode = .scaleToFill
        inputStack.translatesAutoresizingMaskIntoConstraints = false
        inputStack.addBackground(color: .systemGroupedBackground)
      
        mainStack.addArrangedSubview(inputStack)
        
        let descStack = StepStack(with: LabelDetails(title: NSLocalizedString("COVID_19", comment: "Header"),
                                                                        fontType: BrandFont.subtitle,
            textAlignment: .left),
                                  imageDetails: ImageDetails(image: #imageLiteral(resourceName: "virus"), space: 1.0), noTint: true)
        descStack.alignment = .center
        mainStack.addArrangedSubview(descStack)
        
        if UIDevice().userInterfaceIdiom == .phone && (UIScreen.main.bounds.height == 812 || UIScreen.main.bounds.height == 896 ){
            viBottomHeightConstraint.constant = 83
        }
    }
    
}
