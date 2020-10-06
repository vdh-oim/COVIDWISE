/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that manages a layout of known exposure events.
*/

import UIKit
import ExposureNotification
enum Section: Int {
    case overview
    case status
    case exposures
    case privacyPolicy

}
enum Item: Hashable {
    case overviewAction
    case status
    case exposurePlaceholder
    case exposure(index: Int)
    case privacyPolicy

}
class ExposuresViewController: UITableViewController {
    
   let strLearnMore = NSLocalizedString("LEARN_MORE_LINK", comment: "Link")
   let strPrivacyPolicy = NSLocalizedString("PRIVACY_POLICY_LINK_TEXT", comment: "Text")
   let strVirtualVDH = NSLocalizedString("VIRTUAL_VDH", comment: "Text")
   let learnMoreLabel = "TODO"
   let strAskNumber = NSLocalizedString("ASK_PHONE_NUMBER", comment: "AskNumber")
   let strPhoneNumber = NSLocalizedString("PHONE_NUMBER", comment: "PhoneNumber")
   let strLearnMoreTitle = NSLocalizedString("LEARN_MORE_TITLE", comment: "LinkTitle")
    var keyValueObservers = [NSKeyValueObservation]()
    var observers = [NSObjectProtocol]()
    
    static let dateLastPerformedExposureDetectionFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        formatter.formattingContext = .dynamic
        return formatter
    }()
    
    private var pageTitle: String = NSLocalizedString("EXPOSURE_SCREEN_HEADER", comment: "Header")
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        keyValueObservers.append(ExposureManager.shared.manager.observe(\.exposureNotificationStatus) { [unowned self] manager, change in
            self.updateTableView(animated: true, reloadingOverviewAndStatus: true)
        })
        
        observers.append(NotificationCenter.default.addObserver(forName: ExposureManager.authorizationStatusChangeNotification,
                                                                object: nil, queue: nil) { [unowned self] notification in
            self.updateTableView(animated: true, reloadingOverviewAndStatus: true)
        })
        
        observers.append(LocalStore.shared.$exposures.addObserver { [unowned self] in
            self.updateTableView(animated: true)
        })
        
        observers.append(LocalStore.shared.$dateLastPerformedExposureDetection.addObserver { [unowned self] in
            self.reloadStatusSection()
        })
        
        observers.append(LocalStore.shared.$exposureDetectionErrorLocalizedDescription.addObserver { [unowned self] in
            self.reloadStatusSection()
        })
        
        observers.append(NotificationCenter.default.addObserver(forName: UIApplication.significantTimeChangeNotification, object: nil, queue: nil) {
            [unowned self] _ in
            self.reloadStatusSection()
        })
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        self.title = pageTitle
    }
    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    class DataSource: UITableViewDiffableDataSource<Section, Item> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            return nil

            switch snapshot().sectionIdentifiers[section] {
            case .exposures:
                return NSLocalizedString("EXPOSURE_PAST_14_DAYS", comment: "Header")
                return nil
            default:
                return nil
            }
        }
        
        override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
            return nil

            switch snapshot().sectionIdentifiers[section] {
            case .status:
                var messages = [String]()
                if ENManager.authorizationStatus == .authorized && ExposureManager.shared.manager.exposureNotificationStatus == .active {
                    messages.append(NSLocalizedString("EXPOSURE_YOU_WILL_BE_NOTIFIED", comment: "Footer"))
                } else {
                    messages.append(NSLocalizedString("EXPOSURE_YOU_WILL_NOT_BE_NOTIFIED", comment: "Footer"))
                }
                if let localizedErrorDescription = LocalStore.shared.exposureDetectionErrorLocalizedDescription {
                    messages.append(String(format: NSLocalizedString("EXPOSURE_DETECTION_ERROR", comment: "Footer"), localizedErrorDescription))
                }
                if let date = LocalStore.shared.dateLastPerformedExposureDetection {
                    messages.append("\n")
                    let dateString = ExposuresViewController.dateLastPerformedExposureDetectionFormatter.string(from: date)
                    messages.append(String(format: NSLocalizedString("EXPOSURE_LAST_CHECKED", comment: "Footer"), dateString))
                }
                return messages.joined(separator: " ")
            default:
                return nil
            }
        }
    }
    
    @objc func secretPress() {
        let msg = "\(LocalStore.shared.testDeviceName)"
        alert("Device ID", msg, from: self)
    }
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch dataSource.snapshot().sectionIdentifiers[section] {
        case .overview:
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "OverviewHeader") as! TableHeaderView
            header.setCustomButton(color: UIColor.init(red: 0.0/255.0, green: 89.0/255.0, blue: 232.0/255.0, alpha: 1.0))
            /*let secretTapGR = UITapGestureRecognizer(target: self, action: #selector(secretPress))
            secretTapGR.numberOfTouchesRequired = 3
            header.contentView.addGestureRecognizer(secretTapGR)*/
            
            header.headerText = NSLocalizedString("EXPOSURE_NOTIFICATION_OFF", comment: "Header")
            switch ENManager.authorizationStatus {
            case .unknown:
                header.text = NSLocalizedString("EXPOSURE_NOTIFICATION_DISABLED_DIRECTIONS", comment: "Header")
                header.buttonText = NSLocalizedString("EXPOSURE_NOTIFICATION_DENIED_DIRECTIONS", comment: "Header")
                header.button.titleLabel!.font = applyDynamicType(textStyle: .headline, font: BrandFont.subtitle.font);
                header.buttonAction = {
                    self.performSegue(withIdentifier: "ShowOnboarding", sender: nil)
                }
            case .authorized where ExposureManager.shared.manager.exposureNotificationStatus == .bluetoothOff:
                header.text = NSLocalizedString("EXPOSURE_NOTIFICATION_BLUETOOTH_OFF_DIRECTIONS", comment: "Header")
            default:
                header.text = NSLocalizedString("NOTIFY_OTHERS_DENIED_DIRECTIONS", comment: "Header")
                header.buttonText = NSLocalizedString("EXPOSURE_NOTIFICATION_DENIED_DIRECTIONS", comment: "Header")
                header.button.titleLabel!.font = applyDynamicType(textStyle: .headline, font: BrandFont.subtitle.font);
                header.buttonAction = {
                    self.performSegue(withIdentifier: "ShowOnboarding", sender: nil)
                    //openSettings(from: self, coder: NSCoder)
                }
            }
            return header
            
        default:
            return nil
        }
    }
    
    
    
    var dataSource: DataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(TableHeaderView.self, forHeaderFooterViewReuseIdentifier: "OverviewHeader")
        tableView.sectionHeaderHeight = UITableView.automaticDimension;
        tableView.estimatedSectionHeaderHeight = 38
        setupNavigationBar(navigationItem: self.navigationItem, title: pageTitle)

        // if user is not authorized && if user is already onboarded then show Exposure Notification onboarding every time when the app is opened
        if ENManager.authorizationStatus != .authorized && LocalStore.shared.isOnboarded {
            performSegue(withIdentifier: "ShowOnboarding", sender: nil)
        }

        dataSource = DataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
            switch item {
            case .overviewAction:
                let cell = tableView.dequeueReusableCell(withIdentifier: "OverviewAction", for: indexPath)
                switch ENManager.authorizationStatus {
                case .unknown:
                    cell.textLabel!.text = NSLocalizedString("EXPOSURE_NOTIFICATION_DISABLED_ACTION", comment: "Button")
                default:
                    cell.textLabel!.text = ""
                }
                self.accessibilityElement(cell: cell, str: cell.textLabel!.text!)
                return cell
                
            case .status:
                let cell = tableView.dequeueReusableCell(withIdentifier: "Status", for: indexPath)
                var accessbilityStr = ""
                if let label = cell.viewWithTag(101) as? UILabel {
                    label.text = NSLocalizedString("EXPOSURE_INFO_TITLE", comment: "Title")
                    label.font = applyDynamicType(textStyle: .headline, font: BrandFont.title.font)
                    label.textColor = BrandFont.title.color
                    accessbilityStr = accessbilityStr + label.text!
                }
                
                if let label = cell.viewWithTag(102) as? UILabel {
                    label.text = NSLocalizedString("EXPOSURE_NOTIFICATION_STATE_ON", comment: "Value")
                     label.font = applyDynamicType(textStyle: .headline, font: BrandFont.subtitle.font)
                    switch ENManager.authorizationStatus {
                    case .restricted, .notAuthorized:
                        (cell.viewWithTag(101) as? UILabel)?.text = NSLocalizedString("MORE_DETAILS", comment: "Title")
                        label.text = NSLocalizedString("EXPOSURE_NOTIFICATION_STATE_RESTRICTED", comment: "Value")
                        label.textColor = .red
                        accessbilityStr =  ((cell.viewWithTag(101) as? UILabel)?.text)!
                    case .authorized:
                        switch ExposureManager.shared.manager.exposureNotificationStatus {
                        case .active:
                            label.text = NSLocalizedString("EXPOSURE_NOTIFICATION_STATE_ON", comment: "Value")
                            label.textColor = themeDarkGreen
                        case .disabled:
                            (cell.viewWithTag(101) as? UILabel)?.text = NSLocalizedString("MORE_DETAILS", comment: "Title")
                            label.text = NSLocalizedString("EXPOSURE_NOTIFICATION_STATE_OFF", comment: "Value")
                            label.textColor = .red
                            accessbilityStr = ((cell.viewWithTag(101) as? UILabel)?.text)!
                        case .bluetoothOff:
                            (cell.viewWithTag(101) as? UILabel)?.text = NSLocalizedString("MORE_DETAILS", comment: "Title")
                            label.text = NSLocalizedString("EXPOSURE_NOTIFICATION_STATE_BLUETOOTH_OFF", comment: "Value")
                            label.textColor = .red
                            accessbilityStr = ((cell.viewWithTag(101) as? UILabel)?.text)!
                        case .restricted:
                            (cell.viewWithTag(101) as? UILabel)?.text = NSLocalizedString("MORE_DETAILS", comment: "Title")
                            label.text = NSLocalizedString("EXPOSURE_NOTIFICATION_STATE_RESTRICTED", comment: "Value")
                            label.textColor = .red
                            accessbilityStr = ((cell.viewWithTag(101) as? UILabel)?.text)!
                        default:
                            //label.text = NSLocalizedString("EXPOSURE_NOTIFICATION_STATE_UNKNOWN", comment: "Value")
                             (cell.viewWithTag(101) as? UILabel)?.text = NSLocalizedString("MORE_DETAILS", comment: "Title")
                                                       label.text = NSLocalizedString("EXPOSURE_NOTIFICATION_STATE_OFF", comment: "Value")
                                                    label.textColor = .red
                           accessbilityStr =  ((cell.viewWithTag(101) as? UILabel)?.text)!
                        }
                        
                    default:
                        (cell.viewWithTag(101) as? UILabel)?.text = NSLocalizedString("MORE_DETAILS", comment: "Title")
                           label.text = NSLocalizedString("EXPOSURE_NOTIFICATION_STATE_OFF", comment: "Value")
                        label.textColor = .red
                        accessbilityStr = ((cell.viewWithTag(101) as? UILabel)?.text)!
                                
                    }
                    accessbilityStr = accessbilityStr + label.text!
                }
                self.accessibilityElement(cell: cell, str: accessbilityStr)
                return cell
            case .exposurePlaceholder:
                let cell = tableView.dequeueReusableCell(withIdentifier: "ExposurePlaceHolder", for: indexPath)
                var accesbilityStr = ""
                if let label = cell.viewWithTag(101) as? UILabel {
                    label.text = NSLocalizedString("EXPOSURE_DETAILS_TITLE", comment: "Title")
                    label.font = BrandFont.title.font
                    label.textColor = BrandFont.title.color
                    accesbilityStr = accesbilityStr + " " + label.text!
                }
                if let button = cell.viewWithTag(102) as? UIButton {
                    if let _ = LocalStore.shared.dateOfPositiveExposure {
                        button.isHidden = false
                    } else {
                        button.isHidden = true
                    }
                }
                if let label = cell.viewWithTag(103) as? UILabel {
                    label.font = applyDynamicType(textStyle: .headline, font: BrandFont.subtitle.font)
                    label.textColor = .black
                    if let _ = LocalStore.shared.dateOfPositiveExposure {
                        label.text = NSLocalizedString("EXPOSURE_TITLE", comment: "Text")
                    } else {
                        label.text = NSLocalizedString("NO_EXPOSURE_TITLE", comment: "Text")
                    }
                    accesbilityStr = accesbilityStr + " " + label.text!
                }
                if let label = cell.viewWithTag(104) as? UILabel {
                    label.font = applyDynamicType(textStyle: .headline, font: BrandFont.subtitle2.font)
                    label.textColor = BrandFont.subtitle2.color
                    if let _ = LocalStore.shared.dateOfPositiveExposure {
                        label.isUserInteractionEnabled = true
                        label.lineBreakMode = .byWordWrapping
                        let text = NSMutableAttributedString(string: NSLocalizedString("EXPOSURE_DETAILS_TEXT", comment: "Text"))
                        text.replaceCharacters(in: (text.string as NSString).range(of: "%@"), with: daysSinceLastExposureMessage()!);
                        text.replaceCharacters(in: (text.string as NSString).range(of: "%@"),
                                               with: NSAttributedString(string: self.strVirtualVDH,
                                                                        attributes: Step.linkTextAttributes(URL(string: self.strLearnMore)!)));
                        text.replaceCharacters(in: (text.string as NSString).range(of: "%@"),
                                               with: NSAttributedString(string: self.learnMoreLabel,
                                                                        attributes: Step.linkTextAttributes(URL(string: self.strLearnMore)!)));
                        text.replaceCharacters(in: (text.string as NSString).range(of: "%@"),
                                              with: NSAttributedString(string: self.strAskNumber,
                                                 attributes: Step.linkTextAttributes(URL(string: self.strAskNumber)!)));
                        label.attributedText = text
                        let gesture = UITapGestureRecognizer(target:self, action: #selector(self.tapLabel(gesture:)))
                        label.addGestureRecognizer(gesture)
                        
                        text.replaceCharacters(in: (text.string as NSString).range(of: "%$"), with: self.generateNamedIcon(imageName: "userMdChat3"))
                        text.replaceCharacters(in: (text.string as NSString).range(of: "%$"), with: self.generateNamedIcon(imageName: "webBrowser"))
                        text.replaceCharacters(in: (text.string as NSString).range(of: "%$"), with: self.generateNamedIcon(imageName: "smartphone"))
                        label.attributedText = text
                    } else {
                        label.text = NSLocalizedString("NO_EXPOSURE_TEXT", comment: "Text")
                    }
                    accesbilityStr = accesbilityStr + label.text!
                }
                self.accessibilityElement(cell: cell, str: accesbilityStr)
                return cell
                
            case let .exposure(index):
                let cell = tableView.dequeueReusableCell(withIdentifier: "Exposure", for: indexPath)
                let exposure = LocalStore.shared.exposures[index]
                cell.textLabel!.text = NSLocalizedString("POSSIBLE_EXPOSURE", comment: "Text")
                cell.detailTextLabel!.text = DateFormatter.localizedString(from: exposure.date, dateStyle: .long, timeStyle: .none)
                return cell
            case .privacyPolicy:
                let cell = tableView.dequeueReusableCell(withIdentifier: "Privacy", for: indexPath)
                cell.selectionStyle = .none
                if let label = cell.viewWithTag(102) as? UILabel {label.textColor = BrandFont.subtitle.color
                    let text = NSMutableAttributedString(string: NSLocalizedString("PRIVACY_POLICY_LINK_LABEL", comment: "Button"))
                    text.replaceCharacters(in: (text.string as NSString).range(of: "%@"),
                                           with: NSAttributedString(string: self.strPrivacyPolicy,
                                                                    attributes: [
                                                                        .link: URL(string: self.strLearnMore)!,
                                                                        .foregroundColor: UIColor.init(red: 0.0/255.0, green: 89.0/255.0, blue: 232.0/255.0, alpha: 1.0),
                                                                        .underlineColor: UIColor.init(red: 0.0/255.0, green: 89.0/255.0, blue: 232.0/255.0, alpha: 1.0),
                                                                        .underlineStyle: NSUnderlineStyle.single.rawValue]));
                    label.attributedText = text;
                    let gesture = UITapGestureRecognizer(target:self, action: #selector(self.tapLabel(gesture:)))
                    label.addGestureRecognizer(gesture)
                }
                return cell
            }
        })
        dataSource.defaultRowAnimation = .fade
        updateTableView(animated: false)
    }
    @objc func tapLabel(gesture: UITapGestureRecognizer){
        guard let lbl:UILabel = gesture.view as? UILabel else {
            return
        }
        guard let text = lbl.text else {
            return
        }
        let rangeLinkMore = (text as NSString).range(of:self.learnMoreLabel)
        let rangePrivacyPolicy = (text as NSString).range(of: self.strPrivacyPolicy)
        let rangeVirtualVDH = (text as NSString).range(of:self.strVirtualVDH)
        let rangeAsk = (text as NSString).range(of:self.strAskNumber)
        let rangePhone = (text as NSString).range(of:self.strPhoneNumber)
        
        if gesture.didTapAttributedTextInLabel(label: lbl, inRange: rangeLinkMore) {
            performSegue(withIdentifier: "showLearnMoreExposure", sender: nil)
        }else if gesture.didTapAttributedTextInLabel(label: lbl, inRange: rangePrivacyPolicy) {
            performSegue(withIdentifier: "ShowPrivacyPolicy", sender: nil)
        }else if gesture.didTapAttributedTextInLabel(label: lbl, inRange: rangeVirtualVDH) {
            _ = self.tabBarController?.selectedIndex = SMLConfig.virtualTabIndex
        }else if gesture.didTapAttributedTextInLabel(label: lbl, inRange: rangeAsk) {
            let url = URL(string: "telprompt://\(self.strAskNumber)")!
            UIApplication.shared.open(url, options:[:] , completionHandler: nil)
        }else if gesture.didTapAttributedTextInLabel(label: lbl, inRange: rangePhone) {
            let url = URL(string: "telprompt://\(self.strPhoneNumber)")!
            UIApplication.shared.open(url, options:[:] , completionHandler: nil)
        }else {
        }
    }
    @IBSegueAction func showLearnMoreExposure(_ coder: NSCoder) -> LocalWebViewController?
    {
        return LocalWebViewController(with: WebViewModel(title: self.strLearnMoreTitle, urlString: self.strLearnMore), coder: coder)
    }
    func updateTableView(animated: Bool, reloadingOverviewAndStatus: Bool = false) {
        DispatchQueue.main.async {
            
            guard self.isViewLoaded else { return }
            var snapshot = self.dataSource.snapshot()
            snapshot.deleteAllItems()
            
            let authorizationStatus = ENManager.authorizationStatus
            if authorizationStatus != .authorized || ExposureManager.shared.manager.exposureNotificationStatus == .bluetoothOff {
                snapshot.appendSections([.overview])
                if authorizationStatus != .authorized {
//                    snapshot.appendItems([.overviewAction], toSection: .overview)
                }
                if reloadingOverviewAndStatus {
                    snapshot.reloadSections([.overview])
                }
            }
            
            snapshot.appendSections([.status])
            snapshot.appendItems([.status], toSection: .status)
            if reloadingOverviewAndStatus {
                snapshot.reloadSections([.status])
            }
            
            snapshot.appendSections([.exposures])
            if ENManager.authorizationStatus == .authorized && ExposureManager.shared.manager.exposureNotificationStatus == .active {
                snapshot.appendItems([.exposurePlaceholder], toSection: .exposures)
            }
            snapshot.appendItems([.privacyPolicy])

            self.dataSource.apply(snapshot, animatingDifferences: self.tableView.window != nil ? animated : false)
        }
    }
    
    func generateNamedIcon(imageName: String) -> NSAttributedString {
        let image = UIImage(named: imageName)
        let iconImage = image?.colorImage(with: UIColor(alpha:1.0 ))
        let imageWidth = iconImage?.size.width
        let imageHeight = iconImage?.size.height
        let nsTextAtt = NSTextAttachment()
        nsTextAtt.image = iconImage
        nsTextAtt.bounds = CGRect(x: 0.0, y: (BrandFont.subtitle2.font.capHeight - (imageHeight ?? 0.0)).rounded()/2, width: imageWidth ?? 0.0, height: imageHeight ?? 0.0);
        return NSAttributedString(attachment: nsTextAtt)
    }
    
    func reloadStatusSection() {
        guard isViewLoaded else { return }
        var snapshot = dataSource.snapshot()
        snapshot.reloadSections([.status])
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch dataSource.itemIdentifier(for: indexPath)! {
        case .exposurePlaceholder:
            return false
        default:
            return true
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch dataSource.itemIdentifier(for: indexPath)! {
        case .overviewAction:
            switch ENManager.authorizationStatus {
            case .unknown:
                performSegue(withIdentifier: "ShowOnboarding", sender: nil)
            default:
                openSettings(from: self)
            }
        case let .exposure(index):
            let exposureDetailsViewController = ExposureDetailsViewController.make(value: LocalStore.shared.exposures[index])
            present(StepNavigationController(rootViewController: exposureDetailsViewController), animated: true, completion: nil)
        case .privacyPolicy:
            break
            //performSegue(withIdentifier: "ShowPrivacyPolicy", sender: nil)
            //UIApplication.shared.open(SMLConfig.PrivacyPolicyURL)

        default:
            break
        }
    }
    
    @IBSegueAction func showOnboarding(_ coder: NSCoder) -> OnboardingViewController? {
        return OnboardingViewController(rootViewController: OnboardingViewController.EnableExposureNotificationsViewController.make(), coder: coder)
    }
    @IBSegueAction func showPrivacyPolicy(_ coder: NSCoder) -> LocalWebViewController? {
        return LocalWebViewController(with: WebViewModel(title: NSLocalizedString("PRIVACY_POLICY_LINK_TEXT", comment: "Text"), urlString: SMLConfig.PrivacyPolicyURL.absoluteString), coder: coder)
    }
    
    func accessibilityElement(cell:UITableViewCell, str:String) //-> UIAccessibilityElement
    {
        let contentA11yElt = UIAccessibilityElement(accessibilityContainer: cell)
        contentA11yElt.accessibilityTraits = UIAccessibilityTraits.staticText
        contentA11yElt.accessibilityFrameInContainerSpace = cell.contentView.frame
        contentA11yElt.accessibilityLabel = str
        cell.accessibilityLabel = str
        cell.contentView.isAccessibilityElement = true
        cell.accessibilityElements = [contentA11yElt]
        //return contentA11yElt
    }
}


