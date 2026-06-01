//
//  BookmarkConnectionSettingsViewController.swift
//  OpenCloud
//
//  Copyright © 2026 OpenCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2026, OpenCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://opencloud.eu/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import OpenCloudSDK
import OpenCloudAppShared

class BookmarkConnectionSettingsViewController: StaticTableViewController {

	private let bookmark: OCBookmark

	init(bookmark: OCBookmark) {
		self.bookmark = bookmark
		super.init(style: .insetGrouped)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = OCLocalizedString("Connection", nil)

		addSection(makeCustomHTTPHeaderSection())
		addSection(makeClientCertificatePlaceholderSection())
	}

	private func makeCustomHTTPHeaderSection() -> StaticTableViewSection {
		let nameRow = StaticTableViewRow(textFieldWithAction: { [weak self] (_, sender, action) in
			guard let self, let textField = sender as? UITextField, action == .changed else { return }
			self.setUserInfo(textField.text, for: OCBookmarkUserInfoKey.customHTTPHeaderName)
		}, placeholder: OCLocalizedString("Header name", nil),
		   value: (bookmark.userInfo[OCBookmarkUserInfoKey.customHTTPHeaderName] as? String) ?? "",
		   autocorrectionType: .no,
		   identifier: "custom-http-header-name")

		let valueRow = StaticTableViewRow(textFieldWithAction: { [weak self] (_, sender, action) in
			guard let self, let textField = sender as? UITextField, action == .changed else { return }
			self.setUserInfo(textField.text, for: OCBookmarkUserInfoKey.customHTTPHeaderValue)
		}, placeholder: OCLocalizedString("Header value", nil),
		   value: (bookmark.userInfo[OCBookmarkUserInfoKey.customHTTPHeaderValue] as? String) ?? "",
		   autocorrectionType: .no,
		   identifier: "custom-http-header-value")

		return StaticTableViewSection(headerTitle: OCLocalizedString("Custom HTTP Header", nil),
		                              footerTitle: OCLocalizedString("Attached to every request for this account. Useful for reverse-proxy authentication.", nil),
		                              identifier: "section-custom-http-header",
		                              rows: [nameRow, valueRow])
	}

	private func makeClientCertificatePlaceholderSection() -> StaticTableViewSection {
		let placeholderRow = StaticTableViewRow(rowWithAction: nil,
		                                        title: OCLocalizedString("Import certificate (.p12)…", nil),
		                                        accessoryType: .disclosureIndicator,
		                                        identifier: "client-certificate-placeholder")
		placeholderRow.enabled = false
		placeholderRow.selectable = false

		return StaticTableViewSection(headerTitle: OCLocalizedString("Client Certificate", nil),
		                              footerTitle: nil,
		                              identifier: "section-client-certificate",
		                              rows: [placeholderRow])
	}

	private func setUserInfo(_ value: String?, for key: OCBookmarkUserInfoKey) {
		if let value, !value.isEmpty {
			bookmark.userInfo[key] = value as NSString
		} else {
			bookmark.userInfo.removeObject(forKey: key)
		}
	}
}
