//
//  LicenseOfferView.swift
//  OpenCloud
//
//  Created by Felix Schwarz on 11.12.19.
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

#if !DISABLE_APPSTORE_LICENSING

import UIKit
import OpenCloudApp
import OpenCloudAppShared

class LicenseOfferView: UIView, Themeable {
	var offer: OCLicenseOffer
	var feature: OCLicenseFeature?
	var environment: OCLicenseEnvironment
	weak var baseViewController: UIViewController?

	private var stateObservation : NSKeyValueObservation?

	init(with offer: OCLicenseOffer, focusedOn feature: OCLicenseFeature? = nil, in environment: OCLicenseEnvironment, baseViewController: UIViewController?) {
		self.offer = offer
		self.feature = feature
		self.environment = environment
		self.baseViewController = baseViewController

		super.init(frame: .zero)
		self.translatesAutoresizingMaskIntoConstraints = false

		buildView()

		stateObservation = self.offer.observe(\OCLicenseOffer.state, options: .initial) { [weak self] (_, _) in
			self?.updateOfferFromState()
		}

		Theme.shared.register(client: self, applyImmediately: true)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	var localizedTitle : String {
		return offer.localizedTitle ?? (offer.product?.localizedName ?? offer.productIdentifier.rawValue)
	}

	var localizedDescription : String {
		return offer.localizedDescription ?? (offer.product?.localizedDescription ?? offer.productIdentifier.rawValue)
	}

	var titleLabel : UILabel?
	var descriptionLabel : UILabel?

	var pricingDivider : ThemeCSSView?
	var pricingLabel : UILabel?

	var purchaseButton : LicenseOfferButton?
	var purchaseBusyView : ProgressView?

	private let titleLabelSize : CGFloat = 20
	private let descriptionLabelSize : CGFloat = 17
	private let tryLabelSize : CGFloat = 15
	private let priceLabelSize : CGFloat = 17

	func buildView() {
		titleLabel = UILabel()
		descriptionLabel = UILabel()

		guard let titleLabel = titleLabel else { return }
		guard let descriptionLabel = descriptionLabel else { return }

		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

		titleLabel.font = UIFont.systemFont(ofSize: self.titleLabelSize, weight: .semibold)
		descriptionLabel.font = UIFont.systemFont(ofSize: self.descriptionLabelSize)

		descriptionLabel.numberOfLines = 0

		titleLabel.text = self.localizedTitle
		descriptionLabel.text = self.localizedDescription

		self.addSubview(titleLabel)
		self.addSubview(descriptionLabel)

		titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
		descriptionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
		self.setContentCompressionResistancePriority(.required, for: .vertical)

		var constraints = [
			titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor),
			titleLabel.topAnchor.constraint(equalTo: self.topAnchor),

			descriptionLabel.leftAnchor.constraint(equalTo: self.leftAnchor),
			descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5)
		]

		if offer.type == .purchase {
			purchaseButton = LicenseOfferButton(purchaseButtonWithTitle: offer.localizedPriceTag, target: self, action: #selector(takeOffer))
			guard let purchaseButton = purchaseButton else { return }

			self.addSubview(purchaseButton)

			constraints.append(contentsOf: [
				purchaseButton.rightAnchor.constraint(equalTo: self.rightAnchor),
				purchaseButton.topAnchor.constraint(equalTo: self.topAnchor),

				titleLabel.rightAnchor.constraint(lessThanOrEqualTo: purchaseButton.leftAnchor, constant: -10),
				descriptionLabel.rightAnchor.constraint(lessThanOrEqualTo: purchaseButton.leftAnchor, constant: -10)
			])
		} else {
			constraints.append(contentsOf: [
				titleLabel.rightAnchor.constraint(equalTo: self.rightAnchor),
				descriptionLabel.rightAnchor.constraint(equalTo: self.rightAnchor)
			])
		}

		if offer.type == .subscription {
			pricingLabel = UILabel()
			pricingLabel?.translatesAutoresizingMaskIntoConstraints = false
			guard let pricingLabel = pricingLabel else { return }

			purchaseButton = LicenseOfferButton(subscribeButtonWithTitle: OCLocalizedString("Subscribe Now", nil), target: self, action: #selector(takeOffer))
			guard let purchaseButton = purchaseButton else { return }

			var pricingLabelText : String = ""
			var boldTextLength : Int = 0

			if let trialDuration = offer.trialDuration, offer.state(in: environment) != .expired {
				pricingLabelText = NSString(format: OCLocalizedString("%@ / %@", nil) as NSString, offer.localizedPriceTag, offer.subscriptionTermDuration.localizedDescription) as String
				pricingLabelText = "\(pricingLabelText)\n"
				boldTextLength = pricingLabelText.count

				pricingLabelText = pricingLabelText.appendingFormat(OCLocalizedString("after free %@ trial", nil) as NSString, trialDuration.localizedDescriptionSingular) as String
			} else {
				// No trial available (either in general, or because user already has subscribed once)
				pricingLabelText = pricingLabelText.appendingFormat(OCLocalizedString("%@ / %@ – starting immediately", nil), offer.localizedPriceTag, offer.subscriptionTermDuration.localizedDescription)
			}

			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.lineHeightMultiple = 1.5

			let formattedPricingLabelText = NSMutableAttributedString(string: pricingLabelText, attributes: [
				.font : UIFont.systemFont(ofSize: tryLabelSize),
				.paragraphStyle : paragraphStyle
			])

			if boldTextLength > 0 {
				formattedPricingLabelText.addAttribute(.font, value: UIFont.systemFont(ofSize: priceLabelSize, weight: .bold), range: NSRange(location: 0, length: boldTextLength))
			}

			pricingLabel.attributedText = formattedPricingLabelText
			pricingLabel.numberOfLines = 0
			pricingLabel.setContentCompressionResistancePriority(.required, for: .vertical)

			titleLabel.textAlignment = .center
			descriptionLabel.textAlignment = .center
			pricingLabel.textAlignment = .center

			pricingDivider = ThemeCSSView(withSelectors: [.separator])
			pricingDivider?.translatesAutoresizingMaskIntoConstraints = false
			guard let pricingDivider = pricingDivider else { return }

			self.addSubview(pricingLabel)
			self.addSubview(purchaseButton)
			self.addSubview(pricingDivider)

			constraints.append(contentsOf: [
				pricingDivider.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 10),
				pricingDivider.heightAnchor.constraint(equalToConstant: 1),
				pricingDivider.leftAnchor.constraint(equalTo: self.leftAnchor),
				pricingDivider.rightAnchor.constraint(equalTo: self.rightAnchor),

				pricingLabel.topAnchor.constraint(equalTo: pricingDivider.bottomAnchor, constant: 10),
				pricingLabel.leftAnchor.constraint(equalTo: self.leftAnchor),
				pricingLabel.rightAnchor.constraint(equalTo: self.rightAnchor),

				purchaseButton.topAnchor.constraint(equalTo: pricingLabel.bottomAnchor, constant: 20),
				purchaseButton.leftAnchor.constraint(equalTo: self.leftAnchor),
				purchaseButton.rightAnchor.constraint(equalTo: self.rightAnchor),
				purchaseButton.bottomAnchor.constraint(equalTo: self.bottomAnchor)
			])
		} else {
			constraints.append(contentsOf: [
				descriptionLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor)
			])
		}

		if let purchaseButton = purchaseButton {
			let progress = Progress.indeterminate()
			progress.isCancellable = false

			purchaseBusyView = ProgressView()
			purchaseBusyView?.translatesAutoresizingMaskIntoConstraints = false
			purchaseBusyView?.progress = progress

			guard let purchaseBusyView = purchaseBusyView else { return }
			self.addSubview(purchaseBusyView)

			constraints.append(contentsOf: [
				purchaseBusyView.centerXAnchor.constraint(equalTo: purchaseButton.centerXAnchor),
				purchaseBusyView.centerYAnchor.constraint(equalTo: purchaseButton.centerYAnchor)
			])
		}

		NSLayoutConstraint.activate(constraints)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		titleLabel?.applyThemeCollection(collection)
		descriptionLabel?.applyThemeCollection(collection)
		pricingLabel?.applyThemeCollection(collection)
	}

	@objc func takeOffer() {
		offer.commit(options: [
			.baseViewController : self.baseViewController as Any
		], errorHandler: { [weak self] (error) in
			guard let error = error else { return }

			OnMainThread {
				guard let self = self else { return }

				let alertController = ThemedAlertController(title: OCLocalizedString("Purchase failed", nil), message: error.localizedDescription, preferredStyle: .alert)

				let nsError = error as NSError
				if nsError.domain == OCLicenseAppStoreProviderErrorDomain, nsError.code == OCLicenseAppStoreProviderError.purchasesNotAllowedForVPPCopies.rawValue {
					alertController.addAction(UIAlertAction(title: OCLocalizedString("More information", nil), style: .default, handler: { (_) in
						UIApplication.shared.open(URL(string: "https://opencloud.eu/mobile-apps/#ios-emm")!, options: [ : ], completionHandler: nil)
					}))
				}

				alertController.addAction(UIAlertAction(title: OCLocalizedString("OK", nil), style: .default, handler: nil))

				self.baseViewController?.present(alertController, animated: true, completion: nil)
			}
		})
	}

	func updateOfferFromState() {
		var buttonTitle = purchaseButton?.originalTitle
		var buttonEnabled = true

		purchaseBusyView?.isHidden = true
		purchaseButton?.isHidden = false

		switch offer.state(in: environment) {
			case .uncommitted, .expired:
				buttonEnabled = true

			case .unavailable:
				buttonEnabled = false

			case .redundant:
				buttonEnabled = false
				buttonTitle = OCLocalizedString("Unlocked", nil)

			case .inProgress:
				purchaseButton?.isHidden = true
				purchaseBusyView?.isHidden = false

			case .committed:
				buttonEnabled = false
				buttonTitle = OCLocalizedString("Unlocked", nil)
		}

		purchaseButton?.isEnabled = buttonEnabled

		if let buttonTitle = buttonTitle {
			purchaseButton?.setTitle(buttonTitle, for: .normal)
		}
	}
}

#endif
