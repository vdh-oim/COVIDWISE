
/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that shows details for a single diagnosis.
*/

import UIKit

class TestResultDetailsViewController: UITableViewController {
    
    let testResultID: UUID
    
    var observers = [NSObjectProtocol]()
    
    init?(testResultID: UUID, coder: NSCoder) {
        self.testResultID = testResultID
        super.init(coder: coder)
        
        observers.append(LocalStore.shared.$testResults.addObserver { [unowned self] in
            if LocalStore.shared.testResults[self.testResultID] != nil {
                self.updateTableView(animated: true)
                self.reloadShareItem()
            } else {
                self.navigationController!.popViewController(animated: true)
            }
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    enum Section: Hashable {
        case details
        case actions
    }
    
    enum Item: Hashable {
        case diagnosis
        case administrationDate
        case share
        case delete
    }
    
    class DataSource: UITableViewDiffableDataSource<Section, Item> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            switch snapshot().sectionIdentifiers[section] {
            case .details:
                return NSLocalizedString("TEST_RESULT_DETAILS", comment: "Header")
            default:
                return nil
            }
        }
    }
    
    var dataSource: DataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpNavigationBar()
        dataSource = DataSource(tableView: tableView, cellProvider: { [testResultID] tableView, indexPath, item in
            switch item {
            case .diagnosis:
                let cell = tableView.dequeueReusableCell(withIdentifier: "Detail", for: indexPath)
                cell.textLabel!.text = NSLocalizedString("TEST_RESULT_DIAGNOSIS", comment: "Label")
                cell.detailTextLabel!.text = NSLocalizedString("TEST_RESULT_DIAGNOSIS_POSITIVE", comment: "Value")
                return cell
            case .administrationDate:
                let cell = tableView.dequeueReusableCell(withIdentifier: "Detail", for: indexPath)
                let testResult = LocalStore.shared.testResults[testResultID]!
                cell.textLabel!.text = NSLocalizedString("TEST_RESULT_ADMINISTRATION_DATE", comment: "Label")
                cell.detailTextLabel!.text = DateFormatter.localizedString(from: testResult.dateAdministered, dateStyle: .long, timeStyle: .none)
                return cell
            case .share:
                let cell = tableView.dequeueReusableCell(withIdentifier: "Action", for: indexPath)
                let testResult = LocalStore.shared.testResults[testResultID]!
                cell.textLabel!.text = testResult.isShared ?
                    NSLocalizedString("TEST_RESULT_SHARED", comment: "Disabled button") :
                    NSLocalizedString("TEST_RESULT_SHARE", comment: "Button")
                cell.textLabel!.tintColor = nil
                cell.textLabel!.numberOfLines = 0
                cell.textLabel!.tintAdjustmentMode = testResult.isShared ? .dimmed : .automatic
                return cell
            case .delete:
                let cell = tableView.dequeueReusableCell(withIdentifier: "Action", for: indexPath)
                cell.textLabel!.text = NSLocalizedString("TEST_RESULT_DELETE", comment: "Button")
                cell.textLabel!.numberOfLines = 0
                cell.textLabel!.tintColor = .systemRed
                cell.textLabel!.tintAdjustmentMode = .automatic
                cell.accessibilityTraits = .button
                return cell
            }
        })
        dataSource.defaultRowAnimation = .fade
        updateTableView(animated: false)
    }
    
    func updateTableView(animated: Bool) {
        guard isViewLoaded else { return }
        var snapshot = dataSource.snapshot()
        snapshot.deleteAllItems()
        snapshot.appendSections([.details, .actions])
        snapshot.appendItems([.diagnosis, .administrationDate], toSection: .details)
        //snapshot.appendItems([.share, .delete], toSection: .actions)
        snapshot.appendItems([.share], toSection: .actions)
        dataSource.apply(snapshot, animatingDifferences: tableView.window != nil ? animated : false)
    }
    
    func reloadShareItem() {
        guard isViewLoaded else { return }
        var snapshot = dataSource.snapshot()
        snapshot.reloadItems([.share])
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func setUpNavigationBar() {
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "",
                                                                                              style: .plain,
                                                                                              target: nil,
                                                                                              action: nil)
        self.navigationController?.navigationBar.topItem?.title = ""
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "Roboto-Medium", size: 20)!,
                                                                        NSAttributedString.Key.foregroundColor: UIColor.white]
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch dataSource.itemIdentifier(for: indexPath)! {
        case .diagnosis, .administrationDate:
            return false
        case .share:
            return !LocalStore.shared.testResults[testResultID]!.isShared
        case .delete:
            return true
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch dataSource.itemIdentifier(for: indexPath)! {
        case .share:
            performSegue(withIdentifier: "SharePositiveDiagnosis", sender: nil)
        case .delete:
            let alertController = UIAlertController(title: NSLocalizedString("TEST_RESULT_DELETE_ALERT", comment: "Alert title"),
                                                    message: nil, preferredStyle: .actionSheet)
            alertController.addAction(
                .init(title: NSLocalizedString("TEST_RESULT_DELETE", comment: "Button"), style: .destructive) { action in
                    LocalStore.shared.testResults.removeValue(forKey: self.testResultID)
                }
            )
            alertController.addAction(.init(title: NSLocalizedString("CANCEL", comment: "Button"), style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        default:
            break
        }
    }
    
    @IBSegueAction func sharePositiveDiagnosis(_ coder: NSCoder) -> TestVerificationViewController? {
//        return TestVerificationViewController(
//            rootViewController: TestVerificationViewController.ReviewViewController1.make(testResultID: testResultID), coder: coder)
        return nil
    }
}
