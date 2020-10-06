/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that manages the process of notifying others about a positive diagnosis.
*/

import UIKit
import ExposureNotification

let learnMoreAboutNotifyOthers = NSLocalizedString("LEARN_MORE_LINK", comment: "Link")

class NotifyOthersViewController: UITableViewController {
    
    var observers = [NSObjectProtocol]()
    var dataSource: DataSource!
    private let pageTitle: String = NSLocalizedString("NOTIFY_OTHERS_SCREEN_HEADER", comment: "Header")
    enum Section: Int {
        case overview
        case testResults
    }
    enum Item: Hashable {
        case overviewAction
        case testResult(id: UUID)
    }
    //MARK:- Default Functions
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        observers.append(NotificationCenter.default.addObserver(forName: ExposureManager.authorizationStatusChangeNotification,
                                                                object: nil, queue: nil) { [unowned self] notification in
                                                                    self.updateTableView(animated: true, reloadingOverview: true)
        })
        
        observers.append(LocalStore.shared.$testResults.addObserver { [unowned self] in
            self.updateTableView(animated: true)
        })
    }
    
    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        self.title = pageTitle
    }
    override func viewDidLoad() {
        super.viewDidLoad()
      
        setupNavigationBar(navigationItem: self.navigationItem, title: pageTitle)
        tableView.register(TableHeaderView.self, forHeaderFooterViewReuseIdentifier: "OverviewHeader")
        dataSource = DataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
            switch item {
            case .overviewAction:
                let cell = tableView.dequeueReusableCell(withIdentifier: "Action", for: indexPath)
                switch ENManager.authorizationStatus {
                case .authorized:
                    //cell.textLabel!.text = NSLocalizedString("NOTIFY_OTHERS_ACTION", comment: "Button").uppercased()
                    cell.textLabel?.text = ""
                    cell.textLabel?.textColor = .white
                    
                    if let button = cell.viewWithTag(102) as? UIButton {
                        button.addCardShadow(color: UIColor.lightGray, cardShadow: cardShadow)
                        button.layer.masksToBounds = true
                        
                        button.setTitle(NSLocalizedString("NOTIFY_OTHERS_ACTION", comment: "Button").uppercased(), for: .normal)
                        button.titleLabel?.font = UIFont(name: "Roboto-Medium", size: 15.0)
                        button.sizeToFit()
                        button.backgroundColor =  themeDarkGreen
                    }
                    
                case .unknown:
                    break
                    
                default:
                    cell.textLabel!.text = ""
                }
                return cell
            case let .testResult(id):
                let cell = tableView.dequeueReusableCell(withIdentifier: "TestResult", for: indexPath)
                let testResult = LocalStore.shared.testResults[id]!
                let localTime = testResult.dateAdministered.toLocalTime()
                let dateString = DateFormatter.localizedString(from: localTime, dateStyle: .long, timeStyle: .none)
                let sharedColor = testResult.isShared ? themeDarkGreen : UIColor.systemRed
                cell.textLabel!.text = NSLocalizedString("TEST_RESULT_DIAGNOSIS_POSITIVE", comment: "Value")
                let detailString = NSMutableAttributedString(string: "%@ – %@", attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .caption1),
                    .foregroundColor: UIColor.secondaryLabel
                ])
                detailString.replaceCharacters(in: (detailString.string as NSString).range(of: "%@"), with: dateString)
                detailString.replaceCharacters(in: (detailString.string as NSString).range(of: "%@"),
                                               with: NSAttributedString(string: testResult.isShared ?
                                                NSLocalizedString("TEST_RESULT_STATE_SHARED", comment: "Value") :
                                                NSLocalizedString("TEST_RESULT_STATE_NOT_SHARED", comment: "Value"),
                                                                        attributes: [
                                                                            .font: UIFont.preferredFont(forTextStyle: .caption1),
                                                                            .foregroundColor: sharedColor]))
                cell.detailTextLabel!.attributedText = detailString
                //cell.contentView.backgroundColor = UIColor.systemGroupedBackground
                return cell
            }
        })
        dataSource.defaultRowAnimation = .fade
        updateTableView(animated: false)
    }
    
    //MARK:- UITableview DataSource
    class DataSource: UITableViewDiffableDataSource<Section, Item> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            switch snapshot().sectionIdentifiers[section] {
            case .testResults:
                return NSLocalizedString("POSITIVE_DIAGNOSIS", comment: "Header")
            default:
                return nil
            }
        }
    }
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch dataSource.snapshot().sectionIdentifiers[section] {
        case .overview:
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "OverviewHeader") as! TableHeaderView
            header.setCustomButton(color: UIColor.init(red: 0.0/255.0, green: 89.0/255.0, blue: 232.0/255.0, alpha: 1.0))
            // Disable taps to get device id
            /*let secretTapGR = UITapGestureRecognizer(target: self, action: #selector(secretPress))
             secretTapGR.numberOfTouchesRequired = 3
             header.contentView.addGestureRecognizer(secretTapGR)*/
            //header.button.setTitleColor(.blue, for: .normal)
            
            switch ENManager.authorizationStatus {
            case .authorized:
                header.headerText = NSLocalizedString("NOTIFY_OTHERS_HEADER", comment: "Header")
                let description = NSLocalizedString("NOTIFY_OTHERS_DESCRIPTION", comment: "Header").appending("\n\n").appending(NSLocalizedString("LEARN_MORE_LABEL", comment: "Text"))
                let text = NSMutableAttributedString(string: description)
                text.replaceCharacters(in: (text.string as NSString).range(of: "%@"),
                                       with: NSAttributedString(string: NSLocalizedString("LEARN_MORE_LINK", comment: "Link"), attributes: Step.linkTextAttributes(URL(string: learnMoreAboutNotifyOthers)!)))
                header.labelTapAction = {
                    self.performSegue(withIdentifier: "showLearnMoreNotifyOthers", sender: nil)
                }
                header.attributedText = text
                header.buttonAction = {
                    self.performSegue(withIdentifier: "showLearnMoreNotifyOthers", sender: nil)
                }
            case .unknown:
                header.headerText = NSLocalizedString("EXPOSURE_NOTIFICATION_OFF", comment: "Header")
                header.text = NSLocalizedString("NOTIFY_OTHERS_DISABLED_DIRECTIONS", comment: "Header")
                header.buttonText = NSLocalizedString("EXPOSURE_NOTIFICATION_DENIED_DIRECTIONS", comment: "Header")
                header.button.titleLabel!.font = applyDynamicType(textStyle: .headline, font: BrandFont.subtitle.font);
                header.buttonAction = {
                    //openSettings(from: self)
                    self.performSegue(withIdentifier: "ShowOnboarding", sender: nil)
                }
            default:
                header.headerText = NSLocalizedString("EXPOSURE_NOTIFICATION_OFF", comment: "Header")
                header.text = NSLocalizedString("NOTIFY_OTHERS_DENIED_DIRECTIONS", comment: "Header")
                header.buttonText = NSLocalizedString("EXPOSURE_NOTIFICATION_DENIED_DIRECTIONS", comment: "Header")
                header.button.titleLabel!.font = applyDynamicType(textStyle: .headline, font: BrandFont.subtitle.font);
                header.buttonAction = {
                    //openSettings(from: self)
                    self.performSegue(withIdentifier: "ShowOnboarding", sender: nil)
                }
            }
            return header
        default:
            return nil
        }
    }
    func updateTableView(animated: Bool, reloadingOverview: Bool = false) {
        DispatchQueue.main.async {
            guard self.isViewLoaded else { return }
            var snapshot = self.dataSource.snapshot()
            snapshot.deleteAllItems()
            snapshot.appendSections([.overview])
            snapshot.appendItems([.overviewAction], toSection: .overview)
            if reloadingOverview {
                snapshot.reloadSections([.overview])
            }
            let testResults = LocalStore.shared.testResults.filter { $0.value.isAdded && $0.value.isShared}
            if !testResults.isEmpty {
                snapshot.appendSections([.testResults])
                let sortedTestResults = testResults.values.sorted { testResult1, testResult2 in
                    return testResult1.dateAdministered > testResult2.dateAdministered
                }
                snapshot.appendItems(sortedTestResults.map { .testResult(id: $0.id) }, toSection: .testResults)
            }
            self.dataSource.apply(snapshot, animatingDifferences: self.tableView.window != nil ? animated : false)
        }
    }
    //MARK:- UITableview Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch dataSource.itemIdentifier(for: indexPath)! {
        case .overviewAction:
            tableView.deselectRow(at: indexPath, animated: true)
            switch ENManager.authorizationStatus {
            case .authorized:
                performSegue(withIdentifier: "ShowTestVerification", sender: nil)
                //performSegue(withIdentifier: "DummyTestVerification", sender: nil)
                
            case .unknown:
                performSegue(withIdentifier: "ShowOnboarding", sender: nil)
            default:
                openSettings(from: self)
            }
        case .testResult:
            performSegue(withIdentifier: "ShowTestResultDetails", sender: nil)
            //case .privacyPolicy:
            //performSegue(withIdentifier: "ShowPrivacyPolicy", sender: nil)
            //UIApplication.shared.open(SMLConfig.PrivacyPolicyURL)
        }
    }
    //MARK:- IBSegueActions
    @IBSegueAction func ShowTestVerification(_ coder: NSCoder) -> BeforeYouGetStartedViewController? {
        let testResult = MutableTestResult(id: UUID(), isAdded: false, dateAdministered: Date(), isShared: false)
        LocalStore.shared.testResults[testResult.id] = testResult
        return BeforeYouGetStartedViewController.init(with: coder, testResult: testResult)
        
        //return BeforeYouGetStartedViewController.init(with: coder)
    }
        
    @IBSegueAction func showLearnMoreNotifyOthers(_ coder: NSCoder) -> LocalWebViewController? {
        return LocalWebViewController(with: WebViewModel(title: NSLocalizedString("LEARN_MORE_TITLE", comment: "Title"), urlString: learnMoreAboutNotifyOthers), coder: coder)
    }
    @IBSegueAction func showOnboarding(_ coder: NSCoder) -> OnboardingViewController? {
        return OnboardingViewController(rootViewController: OnboardingViewController.EnableExposureNotificationsViewController.make(), coder: coder)
    }
    
    @IBSegueAction func showLearnMore(_ coder: NSCoder) -> OnboardingViewController? {
        return OnboardingViewController(rootViewController: OnboardingViewController.NotifyingOthersViewController.make(independent: true),
                                        coder: coder)
    }
    /*@IBSegueAction func showPrivacyPolicy(_ coder: NSCoder) -> LocalWebViewController? {
           return LocalWebViewController(with: WebViewModel(title: NSLocalizedString("PRIVACY_POLICY_LINK_LABEL", comment: "Button"), urlString: SMLConfig.PrivacyPolicyURL.absoluteString), coder: coder)
    }*/
    @IBSegueAction func showTestResultDetails(_ coder: NSCoder) -> TestResultDetailsViewController? {
        switch dataSource.itemIdentifier(for: tableView.indexPathForSelectedRow!)! {
        case let .testResult(id: id):
            return TestResultDetailsViewController(testResultID: id, coder: coder)
        default:
            preconditionFailure()
        }
    }
    @objc func secretPress() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let developerNavigationViewController: UINavigationController = mainStoryboard.instantiateViewController(identifier: "DeveloperNavigationControllerID")
        developerNavigationViewController.title = "\(LocalStore.shared.testDeviceName)"
        
        if let developerViewController = developerNavigationViewController.viewControllers[0] as? DeveloperViewController {
            let msg = "\(LocalStore.shared.testDeviceName)"
            developerViewController.title = msg
        }
        
        self.present(developerNavigationViewController, animated: true) {
            
        }
    }
}

//MARK: - Extensions
extension String {

    func lineSpaced(_ spacing: Float, color: UIColor = .black) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = CGFloat(spacing)
        let attributedString = NSAttributedString(string: self,
                                                  attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle,
                                                               NSAttributedString.Key.foregroundColor:color])
        return attributedString
    }
}
