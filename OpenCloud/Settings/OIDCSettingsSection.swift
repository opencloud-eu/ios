//
//  OIDCSettingsSection.swift
//  OpenCloud
//
//  Created by Gabriele Pongelli on 26.12.2025.
//
//

/*
 * Copyright (C) 2025, Gabriele Pongelli.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://opencloud.eu/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import OpenCloudSDK
import OpenCloudApp
import OpenCloudAppShared

class OIDCSettingsSection: SettingsSection {
	override init(userDefaults: UserDefaults) {
		super.init(userDefaults: userDefaults)

		self.headerTitle = OCLocalizedString("OIDC settings", nil)

		self.add(row: StaticTableViewRow(rowWithAction: { (_, _) in
		}, title: OCLocalizedString("OIDC Scopes", nil), subtitle: OCLocalizedString("Custom OIDC scopes to be appended to fixed ones.", nil)))

		self.add(row: StaticTableViewRow(textFieldWithAction: { (row, _, _) in
			if let oidcScopes = row.value as? String {
				DisplaySettings.shared.oidcCustomScopes = oidcScopes as NSString
			}
		}, placeholder: "Custom OIDC scopes", value: DisplaySettings.shared.oidcCustomScopes as String, autocorrectionType: UITextAutocorrectionType.no, identifier: "oidc-string"))
	}
}
