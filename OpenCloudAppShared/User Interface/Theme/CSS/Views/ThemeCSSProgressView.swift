//
//  ThemeCSSProgressView.swift
//  OpenCloudAppShared
//
//  Created by Felix Schwarz on 20.03.23.
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

open class ThemeCSSProgressView: UIProgressView, Themeable {
	private var _hasRegistered = false

	open override func didMoveToWindow() {
		super.didMoveToWindow()

		if window != nil, !_hasRegistered {
			_hasRegistered = true
			Theme.shared.register(client: self)
		}
	}

	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		tintColor = collection.css.getColor(.stroke, for: self)
		trackTintColor = collection.css.getColor(.fill, for: self)
	}
}
