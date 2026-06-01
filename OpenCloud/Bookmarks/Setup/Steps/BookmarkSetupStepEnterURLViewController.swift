//
//  BookmarkSetupStepEnterURLViewController.swift
//  OpenCloud
//
//  Created by Felix Schwarz on 06.09.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://opencloud.eu/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import OpenCloudAppShared
import OpenCloudSDK

class BookmarkSetupStepEnterURLViewController: BookmarkSetupStepViewController {
	var urlTextField: UITextField?

	override func loadView() {
		stepTitle = OCLocalizedString("Server URL", nil)

		super.loadView()

		urlTextField = buildTextField(withAction: UIAction(handler: { [weak self] _ in
			self?.updateState()
		}), placeholder: "https://", keyboardType: .URL, autocorrectionType: .no, autocapitalizationType: .none, accessibilityLabel: OCLocalizedString("Server URL", nil), borderStyle: .roundedRect)

		urlTextField?.text = setupViewController?.composer?.configuration.url?.absoluteString

		focusTextFields = [ urlTextField! ]

		let connectionButton = ThemeCSSButton(withSelectors: [])
		connectionButton.setTitle(OCLocalizedString("Connection…", nil), for: .normal)
		connectionButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
		connectionButton.contentHorizontalAlignment = .trailing
		connectionButton.addAction(UIAction(handler: { [weak self] _ in
			self?.openConnectionSettings()
		}), for: .primaryActionTriggered)

		let stack = UIStackView(arrangedSubviews: [ urlTextField!, connectionButton ])
		stack.axis = .vertical
		stack.alignment = .fill
		stack.spacing = 6
		stack.translatesAutoresizingMaskIntoConstraints = false

		contentView = stack

		updateState()
	}

	private func openConnectionSettings() {
		guard let bookmark = setupViewController?.composer?.bookmark else { return }
		let connectionSettings = BookmarkConnectionSettingsViewController(bookmark: bookmark)

		if let navigationController {
			navigationController.pushViewController(connectionSettings, animated: true)
		} else {
			// First-run wizard: BookmarkSetupViewController is the root content view (no nav controller).
			// Wrap and present modally with a Done button so the screen is reachable in this mode too.
			connectionSettings.navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .done, primaryAction: UIAction(handler: { [weak connectionSettings] _ in
				connectionSettings?.dismiss(animated: true)
			}))
			let wrapper = ThemeNavigationController(rootViewController: connectionSettings)
			present(wrapper, animated: true)
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		urlTextField?.becomeFirstResponder()
	}

	func updateState() {
		if let urlString = urlTextField?.text, urlString.count > 0, NSURL(username: nil, password: nil, afterNormalizingURLString: urlString, protocolWasPrepended: nil) != nil {
			continueButton.isEnabled = true
		} else {
			continueButton.isEnabled = false
		}
	}

	override func handleContinue() {
		if let urlString = urlTextField?.text {
			setupViewController?.composer?.enterURL(urlString, completion: composerCompletion)
		}
	}
}
