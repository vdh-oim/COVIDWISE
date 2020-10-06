//
//  BeforeYouGetStartedViewController.swift
//  ExposureNotificationApp
//
//

import UIKit
import Foundation

class BeforeYouGetStartedViewController: BrandViewController {
  
    @IBOutlet weak var mainStack: UIStackView!
    
    @IBOutlet weak var viBottomHeightConstraint: NSLayoutConstraint!
    private var testResult: MutableTestResult!
    
    init?(with coder: NSCoder, testResult: MutableTestResult) {
        self.testResult = testResult
        super.init(with: coder)
    }
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
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = NSLocalizedString("VERIFICATION_START_HEADER", comment: "Header")
    }
    
    @IBOutlet weak var buttonNext: iButton? {
        didSet {
            guard let button = buttonNext else { return }
            button.setTitle(NSLocalizedString("NEXT", comment: "Button").uppercased(), for: .normal)
            button.backgroundColor = themeDarkGreen
            button.didTouchUpInside = { sender in
                self.performSegue(withIdentifier: "ShowTestIdentifier", sender: nil)
//                self.show(TestVerificationViewController.TestIdentifierViewController1.make(testResultID: UUID()), sender: nil)
            }
        }
    }
    @IBSegueAction func ShowTestIdentifier(_ coder: NSCoder) -> TestIdentifierViewController? {
        return TestIdentifierViewController(with: coder, testResult: testResult)
    }
    
    private func loadInputs() {
        view.backgroundColor = UIColor.systemGroupedBackground
        
        let titleStack = StepStack(with: LabelDetails(title: NSLocalizedString("VERIFICATION_START_TITLE", comment: "Title"),
                                                      fontType: BrandFont.title,
                                                      textAlignment: .left))
        let pointsStack = UIStackView()
        for i in 1..<10 {
            let stack = StepStack(with: LabelDetails(title: NSLocalizedString("VERIFICATION_START_TEXT\(i)", comment: "Text"),
                                                                 fontType: BrandFont.subtitle2),
                                              imageDetails: ImageDetails(image: #imageLiteral(resourceName: "checkCircle")), noTint: true)
            pointsStack.addArrangedSubview(stack)
        }
        pointsStack.axis = .vertical
        pointsStack.alignment = .fill
        pointsStack.distribution = .fill
        pointsStack.spacing = 10.0
               
        mainStack.addArrangedSubview(titleStack)
        mainStack.addArrangedSubview(pointsStack)
        
        if UIDevice().userInterfaceIdiom == .phone && (UIScreen.main.bounds.height == 812 || UIScreen.main.bounds.height == 896 ){
            viBottomHeightConstraint.constant = 83
        }
    }
    
}

struct ImageDetails {
    let image: UIImage
    var space: Float = 1.0
}
struct LabelDetails {
    var title: String
    var fontType: BrandFont
    var textAlignment: NSTextAlignment
    var lineSpace: Float
    
    init(title: String, fontType: BrandFont = BrandFont.subtitle, textAlignment: NSTextAlignment = .left, lineSpace: Float = 2.0) {
        self.title = title
        self.fontType = fontType
        self.textAlignment = textAlignment
        self.lineSpace = lineSpace
    }
    
}

class StepStack: UIStackView {
    convenience  init(with labelDetails: LabelDetails, imageDetails: ImageDetails? = nil, noTint:Bool? = false) {
        var array = [UIView]()

        let label = UILabel()
        label.numberOfLines = 0
        label.font = labelDetails.fontType.font
        label.attributedText = labelDetails.title.lineSpaced(labelDetails.lineSpace, color: labelDetails.fontType.color)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = labelDetails.textAlignment
           
        if let imageDetail = imageDetails {
            let button = UIButton(type: .custom)
            if noTint! {
                button.setImage(imageDetail.image, for: .normal)
            }else{
                button.setImage(imageDetail.image.withRenderingMode(.alwaysTemplate), for: .normal)
                button.tintColor = UIColor(alpha: 1.0)
            }
            array.append(button)
               
            NSLayoutConstraint.activate([
                button.layoutMarginsGuide.widthAnchor.constraint(equalToConstant: 20.0),
            ])
        }
        array.append(label)
           
        self.init(arrangedSubviews: array)
        self.axis = .horizontal
        self.alignment = .top
        self.distribution = .fill
        self.spacing = CGFloat(imageDetails?.space ?? 1.0)
        self.contentMode = .scaleToFill
        self.translatesAutoresizingMaskIntoConstraints = false
    }

}

