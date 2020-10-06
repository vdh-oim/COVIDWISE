/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that shows details for a single exposure event.
*/

import UIKit

class ExposureDetailsViewController: ValueStepViewController<Exposure, ExposureDetailsViewController.CustomItem> {
    
    override var step: Step {
        let daysAgo = Calendar.current.dateComponents([.day], from: Date(), to: value.date)
        let daysAgoString = ExposureDetailsViewController.relativeDateFormatter.localizedString(from: daysAgo)
        return Step(
            rightBarButton: .init(item: .done) {
                self.dismiss(animated: true, completion: nil)
            },
            title: NSLocalizedString("EXPOSURE_DETAILS_TITLE", comment: "Title"),
            text: String(format: NSLocalizedString("EXPOSURE_DETAILS_TEXT", comment: "Text"), daysAgoString),
            isModal: false
        )
    }
    
    enum CustomItem: Hashable {
        case details
        case nextSteps
        case footnote
    }
    
    static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.formattingContext = .dynamic
        return formatter
    }()
    
    override func viewDidLoad() {
        tableView.register(UINib(nibName: "ExposureDetailsCell", bundle: nil), forCellReuseIdentifier: "Details")
        tableView.register(UINib(nibName: "ExposureNextStepsCell", bundle: nil), forCellReuseIdentifier: "NextSteps")
        tableView.register(UINib(nibName: "ExposureFootnoteCell", bundle: nil), forCellReuseIdentifier: "Footnote")
        super.viewDidLoad()
        observers.append(NotificationCenter.default.addObserver(forName: UIApplication.significantTimeChangeNotification, object: nil, queue: nil) {
            [unowned self] _ in
            self.updateTableView(animated: true, reloading: [.text])
        })
    }
    
    override var textCellHidesSeparator: Bool { false }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, customItem: CustomItem) -> UITableViewCell {
        switch customItem {
        case .details:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Details", for: indexPath) as! ExposureDetailsCell
            cell.headerLabel.text = NSLocalizedString("EXPOSURE_DETAILS_HEADER", comment: "Header").localizedUppercase
            cell.diagnosisVerificationLabel.text = NSLocalizedString("EXPOSURE_DETAILS_DIAGNOSIS_VERIFICATION", comment: "Text")
//            cell.diagnosisVerificationButton.setTitle(NSLocalizedString("LEARN_MORE", comment: "Link"), for: .normal)
//            cell.diagnosisVerificationButton.addTarget(self, action: #selector(learnMore), for: .touchUpInside)
            let dataString = DateFormatter.localizedString(from: value.date, dateStyle: .long, timeStyle: .none)
            cell.dateLabel.text = String(format: NSLocalizedString("EXPOSURE_DETAILS_DATE_TEXT", comment: "Text"), dataString)
            return cell
        case .nextSteps:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NextSteps", for: indexPath) as! ExposureNextStepsCell
            cell.headerLabel.text = NSLocalizedString("EXPOSURE_NEXT_STEPS_HEADER", comment: "Header").localizedUppercase
            cell.nextStepsLabel.text = NSLocalizedString("EXPOSURE_NEXT_STEPS_TEXT", comment: "Text")
            return cell
        case .footnote:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Footnote", for: indexPath) as! ExposureFootnoteCell
            cell.footnoteLabel.text = NSLocalizedString("EXPOSURE_FOOTNOTE", comment: "Footnote")
            return cell
        }
    }
    
    override func modifySnapshot(_ snapshot: inout NSDiffableDataSourceSnapshot<Section, Item>) {
        snapshot.appendItems([.custom(.details), .custom(.nextSteps), .custom(.footnote)], toSection: .main)
    }
    
    @objc
    func learnMore() {
        let navigationController = StepNavigationController(rootViewController: ExposureLearnMoreViewController.make())
        present(navigationController, animated: true, completion: nil)
    }
}

class ExposureDetailsCell: UITableViewCell {
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var diagnosisVerificationLabel: UILabel!
//    @IBOutlet var diagnosisVerificationButton: UIButton!
    @IBOutlet var dateLabel: UILabel!
}

class ExposureNextStepsCell: UITableViewCell {
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var nextStepsLabel: UILabel!
}

class ExposureFootnoteCell: StepOptionalSeparatorCell {
    @IBOutlet var footnoteLabel: UILabel!
}

class ExposureLearnMoreViewController: StepViewController {
    override var step: Step {
        Step(
            rightBarButton: .init(item: .done) {
                self.dismiss(animated: true, completion: nil)
            },
            title: NSLocalizedString("EXPOSURE_DETAILS_LEARN_TITLE", comment: "Title"),
            text: NSLocalizedString("EXPOSURE_DETAILS_LEARN_TEXT", comment: "Text"),
            isModal: false
        )
    }
}
