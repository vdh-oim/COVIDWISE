/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that manages a standardized visual layout for a single step in a user interface flow.
*/

import UIKit

struct Step {
    
    struct BarButton {
        let item: UIBarButtonItem.SystemItem
        let action: () -> Void
    }
    
    struct Button {
        let title: String
        let isProminent: Bool
        let isEnabled: Bool
        let action: () -> Void
        
        init(title: String, isProminent: Bool = false, isEnabled: Bool = true, action: @escaping () -> Void) {
            self.title = title
            self.isProminent = isProminent
            self.isEnabled = isEnabled
            self.action = action
        }
    }
    
    let hidesNavigationBackButton: Bool
    let rightBarButton: BarButton?
    let title: String
    let text: NSAttributedString
    let urlHandler: ((URL, UITextItemInteraction) -> Bool)?
    let customView: UIView?
    let isModal: Bool
    let buttons: [Button]
    
    static let bodyTextAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.label,
        .font: UIFont.preferredFont(forTextStyle: .body)
    ]
    
    static let headlineTextAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.label,
        .font: UIFont.preferredFont(forTextStyle: .headline)
    ]
    //Added - foregroundColor,underlineColor,underlineStyle
    static func linkTextAttributes(_ link: URL) -> [NSAttributedString.Key: Any] { [
        .font: UIFont.preferredFont(forTextStyle: .body),
        .foregroundColor: UIColor.init(red: 0.0/255.0, green: 89.0/255.0, blue: 232.0/255.0, alpha: 1.0),
        .underlineColor: UIColor.init(red: 0.0/255.0, green: 89.0/255.0, blue: 232.0/255.0, alpha: 1.0),
        .underlineStyle: NSUnderlineStyle.single.rawValue,
        .link: link
    ]}
    
    init(hidesNavigationBackButton: Bool = false,
         rightBarButton: BarButton? = nil,
         title: String,
         text: NSAttributedString,
         urlHandler: ((URL, UITextItemInteraction) -> Bool)? = nil,
         customView: UIView? = nil,
         isModal: Bool = true,
         buttons: [Button] = []) {
        self.hidesNavigationBackButton = hidesNavigationBackButton
        self.rightBarButton = rightBarButton
        self.title = title
        let mutableText = NSMutableAttributedString(attributedString: text)
        let warningBegin = (text.string as NSString).range(of: "{")
        let warningEnd = (text.string as NSString).range(of: "}")
        mutableText.addAttribute(.foregroundColor, value: UIColor.systemOrange, range: warningBegin.union(warningEnd))
        self.text = mutableText
        self.urlHandler = urlHandler
        self.customView = customView
        self.isModal = isModal
        self.buttons = buttons
    }
    
    init(hidesNavigationBackButton: Bool = false,
         rightBarButton: BarButton? = nil,
         title: String,
         text: String,
         urlHandler: ((URL, UITextItemInteraction) -> Bool)? = nil,
         customView: UIView? = nil,
         isModal: Bool = true,
         buttons: [Button] = []) {
        self.init(hidesNavigationBackButton: hidesNavigationBackButton,
                  rightBarButton: rightBarButton,
                  title: title,
                  text: NSAttributedString(string: text, attributes: Step.bodyTextAttributes),
                  urlHandler: urlHandler,
                  customView: customView,
                  isModal: isModal,
                  buttons: buttons)
    }
}

class StepNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.standardAppearance.configureWithOpaqueBackground()
        navigationBar.standardAppearance.shadowColor = nil
    }
}

// Specify an enum type for CustomItem if custom cells are needed for a CustomStepViewController subclass
// If custom cells are not needed for a CustomStepViewController subclass, specify Never, or subclass StepViewController
class CustomStepViewController<CustomItem: Hashable>: UIViewController, UITableViewDelegate, UITextViewDelegate {
    
    // Customization points for subclasses
    
    static func make() -> Self {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "Step", creator: { coder -> Self? in
            return Self(coder: coder)
        })
    }
    
    var step: Step {
        preconditionFailure("Must override step")
    }
    
    var textCellHidesSeparator: Bool { true }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, customItem: CustomItem) -> UITableViewCell {
        preconditionFailure("Must override if using CustomItem")
    }
    
    func modifySnapshot(_ snapshot: inout NSDiffableDataSourceSnapshot<Section, Item>) {
        // For subclasses
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // For subclasses
    }
    
    // Private implementation details
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        navigationItem.hidesBackButton = step.hidesNavigationBackButton
        if let barButton = step.rightBarButton {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: barButton.item,
                                                                target: self, action: #selector(rightBarButtonAction))
        }
        isModalInPresentation = step.isModal
    }
    
    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    var observers = [NSObjectProtocol]()
    var keyboardHeight: CGFloat = 0.0 {
        didSet {
            view.setNeedsLayout()
        }
    }
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var buttonBackgroundView: UIView!
    @IBOutlet var buttonStackView: UIStackView!
    @IBOutlet var button0: PlatterButton!
    @IBOutlet var button1: PlatterButton!
    
    enum Section: Int {
        case main
    }
    
    enum Item: Hashable {
        case title
        case text
        case customView
        case custom(CustomItem)
    }
    
    var dataSource: UITableViewDiffableDataSource<Section, Item>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.register(StepOptionalSeparatorCell.self, forCellReuseIdentifier: "CustomView")
        dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [unowned self] tableView, indexPath, item in
            switch item {
            case .title:
                let cell = tableView.dequeueReusableCell(withIdentifier: "Title", for: indexPath) as! StepTitleCell
                cell.titleLabel.text = self.step.title
                return cell
            case .text:
                let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! StepTextCell
                cell.hidesSeparator = self.textCellHidesSeparator
                cell.textView.attributedText = self.step.text
                return cell
            case .customView:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CustomView", for: indexPath)
                let customView = self.step.customView!
                customView.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(customView)
                NSLayoutConstraint.activate([
                    cell.contentView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: customView.leadingAnchor),
                    cell.contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: customView.trailingAnchor),
                    cell.contentView.topAnchor.constraint(equalTo: customView.topAnchor),
                    cell.contentView.bottomAnchor.constraint(equalTo: customView.bottomAnchor, constant: 16.0)
                ])
                return cell
            case let .custom(customItem):
                return self.tableView(tableView, cellForRowAt: indexPath, customItem: customItem)
            }
        })
        dataSource.defaultRowAnimation = .fade
        updateTableView(animated: false)
        
        buttonBackgroundView.isHidden = step.buttons.isEmpty
        updateButtons()
        
        let keyboardWillChange = UIResponder.keyboardWillChangeFrameNotification
        observers.append(NotificationCenter.default.addObserver(forName: keyboardWillChange, object: nil, queue: nil) { [unowned self] notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect, let window = self.view.window {
                self.keyboardHeight = keyboardFrame.intersection(window.bounds).height
            } else {
                self.keyboardHeight = 0.0
            }
            self.view.layoutIfNeeded()
        })
    }
    
    func updateTableView(animated: Bool, reloading items: [Item] = []) {
        guard isViewLoaded else { return }
        var snapshot = dataSource.snapshot()
        snapshot.deleteAllItems()
        snapshot.appendSections([.main])
        snapshot.appendItems([.title, .text], toSection: .main)
        if step.customView != nil {
            snapshot.appendItems([.customView], toSection: .main)
        }
        modifySnapshot(&snapshot)
        snapshot.reloadItems(items)
        dataSource.apply(snapshot, animatingDifferences: tableView.window != nil ? animated : false)
    }
    
    func updateButtons() {
        func apply(_ stepButton: Step.Button, to platterButton: PlatterButton) {
            UIView.performWithoutAnimation {
                platterButton.setTitle(stepButton.title, for: .normal)
                platterButton.layoutIfNeeded()
            }
            platterButton.isProminent = stepButton.isProminent
            platterButton.isEnabled = stepButton.isEnabled
        }
        
        switch step.buttons.count {
        case 0:
            button0.isHidden = true
            button1.isHidden = true
        case 1:
            apply(step.buttons[0], to: button0)
            button1.isHidden = true
        case 2:
            apply(step.buttons[0], to: button0)
            apply(step.buttons[1], to: button1)
        default:
            assertionFailure("Step cannot have more than 2 buttons.")
        }
    }
    
    override func viewDidLayoutSubviews() {
        let buttonStackHeight = buttonStackView.frame.height
        let effectiveButtonStackHeight = buttonStackHeight == 0.0 ? 0.0 : buttonStackHeight + 32.0
        let effectiveKeyboardHeight = keyboardHeight - self.view.safeAreaInsets.bottom
        tableView.contentInset.bottom = max(effectiveButtonStackHeight, effectiveKeyboardHeight + 32.0)
        tableView.verticalScrollIndicatorInsets.bottom = max(effectiveButtonStackHeight, effectiveKeyboardHeight)
    }
    
    @objc
    func rightBarButtonAction() {
        step.rightBarButton!.action()
    }
    
    @IBAction func button0TouchUpInside() {
        step.buttons[0].action()
    }
    
    @IBAction func button1TouchUpInside() {
        step.buttons[1].action()
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return step.urlHandler?(URL, interaction) ?? true
    }
}

class StepViewController: CustomStepViewController<Never> {}

class StepOptionalSeparatorCell: UITableViewCell {
    var hidesSeparator = true {
        didSet {
            setNeedsLayout()
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if hidesSeparator {
            switch effectiveUserInterfaceLayoutDirection {
            case .rightToLeft:
                separatorInset = UIEdgeInsets(top: 0.0, left: .greatestFiniteMagnitude, bottom: 0.0, right: 0.0)
            default:
                separatorInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: .greatestFiniteMagnitude)
            }
        }
    }
}

class StepTitleCell: StepOptionalSeparatorCell {
    @IBOutlet var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        let titleFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title1).withSymbolicTraits(.traitBold)!
        titleLabel.font = UIFont(descriptor: titleFontDescriptor, size: 0.0)
        titleLabel.accessibilityTraits = .header
    }
}

class StepTextCell: StepOptionalSeparatorCell {
    @IBOutlet var textView: UITextView!
    override func awakeFromNib() {
        super.awakeFromNib()
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0.0
    }
}

class ValueStepViewController<Value, CustomItem: Hashable>: CustomStepViewController<CustomItem> {
    var value: Value
    required init?(value: Value, coder: NSCoder) {
        self.value = value
        super.init(coder: coder)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    static func make(value: Value) -> Self {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "Step", creator: { coder -> Self? in
            return Self(value: value, coder: coder)
        })
    }
}
