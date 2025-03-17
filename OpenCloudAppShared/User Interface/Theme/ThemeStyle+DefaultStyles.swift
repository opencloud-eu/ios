//
//  ThemeStyle+DefaultStyles.swift
//  OpenCloud
//
//  Created by Felix Schwarz on 29.10.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://opencloud.eu/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import OpenCloudSDK

// MARK: - OpenCloud brand colors
extension UIColor {
	static var OpenCloudLightColor : UIColor { return UIColor(hex: 0x20434F) }
	static var OpenCloudDarkColor : UIColor { return UIColor(hex: 0xE2BAFF) }
}

extension ThemeStyle {
	static public func systemLight(with tintColor: UIColor? = nil, cssRecordStrings: [String]? = nil) -> ThemeStyle {
		return (ThemeStyle(styleIdentifier: "com.opencloud.light", darkStyleIdentifier: "com.opencloud.dark", localizedName: OCLocalizedString("Light", nil), lightColor: tintColor ?? UIColor.OpenCloudLightColor, darkColor: .label, themeStyle: .light, useSystemColors: true, systemTintColor: tintColor, cssRecordStrings: cssRecordStrings))
	}
	static public func systemDark(with tintColor: UIColor? = nil, cssRecordStrings: [String]? = nil) -> ThemeStyle {
		return (ThemeStyle(styleIdentifier: "com.opencloud.dark", localizedName: OCLocalizedString("Dark", nil), lightColor: tintColor ?? UIColor.OpenCloudDarkColor, darkColor: .secondarySystemGroupedBackground, themeStyle: .dark, useSystemColors: true, systemTintColor: tintColor, cssRecordStrings: cssRecordStrings))
	}
}
