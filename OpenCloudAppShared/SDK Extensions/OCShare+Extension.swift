//
//  OCItem+Extension.swift
//  OpenCloud
//
//  Created by Felix Schwarz on 13.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
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

import UIKit
import OpenCloudSDK

extension OCShare {
	func copyToClipboard() -> Bool {
		if let url {
			UIPasteboard.general.url = url
			return true
		}
		return false
	}
}
