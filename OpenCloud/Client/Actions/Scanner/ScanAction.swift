//
//  ScanAction.swift
//  OpenCloud
//
//  Created by Felix Schwarz on 28.08.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://opencloud.eu/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import OpenCloudSDK
import OpenCloudApp
import OpenCloudAppShared
import VisionKit

class ScanAction: Action, VNDocumentCameraViewControllerDelegate {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.opencloud.action.scan") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return OCLocalizedString("Scan document", nil) }
	override class var locations : [OCExtensionLocationIdentifier]? { return [ .folderAction, .keyboardShortcut, .emptyFolder ] }
	override class var keyCommand : String? { return "S" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command, .shift] }
	override class var licenseRequirements: LicenseRequirements? { return LicenseRequirements(feature: .documentScanner) }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.count > 1 {
			return .none
		}

		if forContext.items.first?.type != OCItemType.collection {
			return .none
		}

		if forContext.items.first?.permissions.contains(.createFile) == false {
			return .none
		}

		return .middle
	}

	// MARK: - Action implementation
	override func run() {
		guard let viewController = context.viewController else {
			return
		}

		guard self.proceedWithLicensing(from: viewController) else {
			return
		}

		guard context.items.count > 0 else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		guard let targetFolderItem = context.items.first, let itemLocation = targetFolderItem.location else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		guard let core = context.core else {
			completed(with: NSError(ocError: .internal))
			return
		}

		Scanner.scan(on: viewController) { [weak core] (_, _, scan) in
			if let pageCount = scan?.pageCount, pageCount > 0, let scannedPages = scan?.scannedPages {
				var filename : String? = scan?.title

				if filename?.count == 0 {
					filename = nil
				}

				let currentDate = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium) // Use localized date
							.replacingOccurrences(of: ":", with: "-")  // Remove reserved character (":" not usable under Windows)
							.replacingOccurrences(of: "/", with: "-")  // Remove reserved character ("/" used to delimit paths on macOS, iOS, Linux, …)
							.replacingOccurrences(of: "\\", with: "-") // Remove reserved character ("\" used to delimit paths on Windows)

				core?.suggestUnusedNameBased(on: filename ?? "\(OCLocalizedString("Scan", nil)) \(currentDate).pdf", at: itemLocation, isDirectory: true, using: .bracketed, filteredBy: nil, resultHandler: { (suggestedName, _) in
					guard let suggestedName = suggestedName else { return }

					OnMainThread {
						let navigationController = ThemeNavigationController(rootViewController: ScanViewController(with: scannedPages, core: core, fileName: suggestedName, targetFolder: targetFolderItem))
						viewController.present(navigationController, animated: true)
					}
				})
			}
		}
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return UIImage(systemName: "doc.text.viewfinder", withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .regular))?.withRenderingMode(.alwaysTemplate)
	}
}
