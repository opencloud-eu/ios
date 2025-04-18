//
//  MoreStaticTableViewController.swift
//  OpenCloud
//
//  Created by Pablo Carrascal on 17/08/2018.
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

open class MoreStaticTableViewController: StaticTableViewController {

	private var themeApplierTokens: [ThemeApplierToken]

	override public init(style: UITableView.Style) {
		themeApplierTokens = []
		super.init(style: style)

		cssSelectors = [.more]
	}

	deinit {
		themeApplierTokens.forEach({ token in Theme.shared.remove(applierForToken: token) })
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	open override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if let title = (sections[section] as? MoreStaticTableViewSection)?.headerAttributedTitle {
			let containerView = ThemeCSSView(withSelectors: [.sectionHeader])
			let label = ThemeCSSLabel(withSelectors: [.label])
			label.translatesAutoresizingMaskIntoConstraints = false
			containerView.addSubview(label)
			NSLayoutConstraint.activate([
				label.leftAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leftAnchor, constant: 20),
				label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
				label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
				label.rightAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.rightAnchor, constant: -20)
			])

			label.attributedText = title

			let messageApplierToken = Theme.shared.add(applier: { (_, collection, _) in
				label.applyThemeCollection(collection)
			})

			themeApplierTokens.append(messageApplierToken)

			return containerView
		}

		return nil
	}

	open override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if  (sections[section] as? MoreStaticTableViewSection)?.headerAttributedTitle != nil {
			return UITableView.automaticDimension
		}
		return UITableView.automaticDimension
	}

	open override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return CGFloat.leastNormalMagnitude
	}

	open override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return nil
	}
}

open class MoreStaticTableViewSection : StaticTableViewSection {
	public var headerAttributedTitle : NSAttributedString?
	public var footerAttributedTitle : NSAttributedString?

	convenience public init(headerAttributedTitle theHeaderTitle: NSAttributedString? = nil, footerAttributedTitle theFooterTitle: NSAttributedString? = nil, identifier : String? = nil, rows rowsToAdd: [StaticTableViewRow] = Array()) {
		self.init()

		self.headerAttributedTitle = theHeaderTitle
		self.footerAttributedTitle = theFooterTitle

		self.identifier  = identifier

		self.add(rows: rowsToAdd)
	}
}
