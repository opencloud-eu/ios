//
//  Calendar+Extension.swift
//  OpenCloudAppShared
//
//  Created by Matthias Hühne on 27.09.19.
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

import UIKit

public extension Calendar {
	func dateTimeComponents(from date: Date) -> DateComponents {
		let components : Set<Calendar.Component> = [.day, .month, .year, .hour, .minute, .second]
		return self.dateComponents(components, from: date)
	}
}
