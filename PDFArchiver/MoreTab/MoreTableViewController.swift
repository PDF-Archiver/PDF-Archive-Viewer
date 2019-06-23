//
//  MoreTableViewController.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 21.06.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import UIKit

class MoreTableViewController: UITableViewController {

    // Section: preferences
    @IBOutlet private weak var showIntroCell: UITableViewCell!
    @IBOutlet private weak var showPermissionsCell: UITableViewCell!
    // Section: more information
    @IBOutlet weak var macOSAppCell: UITableViewCell!
    @IBOutlet private weak var manageSubscriptionCell: UITableViewCell!
    @IBOutlet private weak var privacyPolicyCell: UITableViewCell!
    @IBOutlet private weak var imprintCell: UITableViewCell!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        let cell = tableView.cellForRow(at: indexPath)
        switch cell {
        case showIntroCell:
            let controller = IntroViewController()
            present(controller, animated: true, completion: nil)

        case showPermissionsCell:
            guard let link = URL(string: UIApplication.openSettingsURLString) else { fatalError("Could not find settings url!") }
            UIApplication.shared.open(link)

        case macOSAppCell:
            guard let link = URL(string: "https://macos.pdf-archiver.io") else { fatalError("Could not parse macOS app url.") }
            UIApplication.shared.open(link)

        case manageSubscriptionCell:
            guard let link = URL(string: "https://apps.apple.com/account/subscriptions") else { fatalError("Could not parse subscription url.") }
            UIApplication.shared.open(link)

        case privacyPolicyCell:
            guard let link = URL(string: NSLocalizedString("MoreTableViewController.privacyPolicyCell.url", comment: "")) else { fatalError("Could not parse termsOfUseCell url.") }
            UIApplication.shared.open(link)

        case imprintCell:
            guard let link = URL(string: NSLocalizedString("MoreTableViewController.imprintCell.url", comment: "")) else { fatalError("Could not parse privacyPolicyCell url.") }
            UIApplication.shared.open(link)

        default:
            fatalError("Could not find the table view cell \(cell?.description ?? "")!")
        }
    }
}