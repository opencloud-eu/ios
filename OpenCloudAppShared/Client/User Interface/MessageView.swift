//
//  MessageView.swift
//  OpenCloud
//
//  Created by Matthias Hühne on 23.04.19.
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

open class MessageView: UIView {

	open var mainView : UIView
	open var messageView : UIView?
	open var messageContainerView : UIView?
	open var messageImageView : VectorImageView?
	open var messageTitleLabel : UILabel?
	open var messageMessageLabel : UILabel?
	open var messageThemeApplierToken : ThemeApplierToken?
	open var composeViewBottomConstraint: NSLayoutConstraint!
	private var compactConstraints: [NSLayoutConstraint] = []
	private var regularConstraints: [NSLayoutConstraint] = []
	open var keyboardHeight : CGFloat = 0

	public init(add to: UIView) {
		mainView = to
		super.init(frame: to.frame)

		// Observe keyboard change
		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
		if messageThemeApplierToken != nil {
			Theme.shared.remove(applierForToken: messageThemeApplierToken)
			messageThemeApplierToken = nil
		}
	}

	open func message(show: Bool, with insets: UIEdgeInsets? = nil, imageName : String? = nil, title : String? = nil, message : String? = nil) {
		if !show {
			if messageView?.superview != nil {
				messageView?.removeFromSuperview()
			}

			return
		}

		if messageView == nil {
			var rootView : UIView
			var containerView : UIView
			var imageView : VectorImageView
			var titleLabel : UILabel
			var messageLabel : UILabel

			rootView = UIView()
			rootView.translatesAutoresizingMaskIntoConstraints = false

			containerView = UIView()
			containerView.translatesAutoresizingMaskIntoConstraints = false

			imageView = VectorImageView()
			imageView.translatesAutoresizingMaskIntoConstraints = false

			titleLabel = UILabel()
			titleLabel.translatesAutoresizingMaskIntoConstraints = false

			messageLabel = UILabel()
			messageLabel.translatesAutoresizingMaskIntoConstraints = false
			messageLabel.numberOfLines = 0
			messageLabel.textAlignment = .center
			messageLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

			containerView.addSubview(imageView)
			containerView.addSubview(titleLabel)
			containerView.addSubview(messageLabel)

			rootView.addSubview(containerView)

			regularConstraints.append(contentsOf: [
				imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
				imageView.bottomAnchor.constraint(equalTo: containerView.centerYAnchor),
				imageView.widthAnchor.constraint(equalToConstant: 96),
				imageView.heightAnchor.constraint(equalToConstant: 96),

				titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
				titleLabel.leftAnchor.constraint(greaterThanOrEqualTo: containerView.leftAnchor),
				titleLabel.rightAnchor.constraint(lessThanOrEqualTo: containerView.rightAnchor),
				titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),

				messageLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
				messageLabel.leftAnchor.constraint(greaterThanOrEqualTo: containerView.leftAnchor),
				messageLabel.rightAnchor.constraint(lessThanOrEqualTo: containerView.rightAnchor),
				messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),

				containerView.centerXAnchor.constraint(equalTo: rootView.centerXAnchor),
				containerView.centerYAnchor.constraint(equalTo: rootView.centerYAnchor),

				containerView.leftAnchor.constraint(greaterThanOrEqualTo: rootView.leftAnchor, constant: 20),
				containerView.rightAnchor.constraint(lessThanOrEqualTo: rootView.rightAnchor, constant: -20),
				containerView.topAnchor.constraint(greaterThanOrEqualTo: rootView.topAnchor, constant: 20),
				containerView.bottomAnchor.constraint(lessThanOrEqualTo: rootView.bottomAnchor, constant: -20)
				])

			compactConstraints.append(contentsOf: [
				imageView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
				imageView.widthAnchor.constraint(equalToConstant: 96),
				imageView.heightAnchor.constraint(equalToConstant: 96),
				imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

				titleLabel.leftAnchor.constraint(equalTo: imageView.rightAnchor, constant: 20),
				titleLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor),
				titleLabel.topAnchor.constraint(equalTo: imageView.topAnchor),

				messageLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
				messageLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor),
				messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),

				containerView.centerXAnchor.constraint(equalTo: rootView.centerXAnchor),
				containerView.centerYAnchor.constraint(equalTo: rootView.centerYAnchor),

				containerView.leftAnchor.constraint(greaterThanOrEqualTo: rootView.leftAnchor, constant: 20),
				containerView.rightAnchor.constraint(lessThanOrEqualTo: rootView.rightAnchor, constant: -20),
				containerView.topAnchor.constraint(greaterThanOrEqualTo: rootView.topAnchor, constant: 20),
				containerView.bottomAnchor.constraint(lessThanOrEqualTo: rootView.bottomAnchor, constant: -20)
				])

			render()

			messageView = rootView
			messageContainerView = containerView
			messageImageView = imageView
			messageTitleLabel = titleLabel
			messageMessageLabel = messageLabel
		}

		if messageView?.superview == nil {
			if let rootView = self.messageView, let containerView = self.messageContainerView {
				containerView.alpha = 0
				containerView.transform = CGAffineTransform(translationX: 0, y: 15)

				rootView.alpha = 0

				self.mainView.addSubview(rootView)

				messageThemeApplierToken = Theme.shared.add(applier: { [weak self] (_, collection, _) in
					self?.messageView?.backgroundColor = collection.css.getColor(.fill, selectors: [.table], for: self?.messageView)

					self?.messageTitleLabel?.applyThemeCollection(collection, itemStyle: .bigTitle)
					self?.messageMessageLabel?.applyThemeCollection(collection, itemStyle: .bigMessage)
				})

				self.composeViewBottomConstraint = rootView.bottomAnchor.constraint(equalTo: self.mainView.safeAreaLayoutGuide.bottomAnchor)
				if keyboardHeight > 0 {
					self.composeViewBottomConstraint.constant = self.mainView.safeAreaInsets.bottom - keyboardHeight
				}

				NSLayoutConstraint.activate([
					rootView.leftAnchor.constraint(equalTo: self.mainView.leftAnchor, constant: insets?.left ?? 0),
					rootView.widthAnchor.constraint(equalTo: self.mainView.widthAnchor, constant: -(insets?.right ?? 0)),
					rootView.topAnchor.constraint(equalTo: self.mainView.safeAreaLayoutGuide.topAnchor, constant: insets?.top ?? 0),
					self.composeViewBottomConstraint
				])

				UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
					rootView.alpha = 1
				}, completion: { (_) in
					UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
						containerView.alpha = 1
						containerView.transform = CGAffineTransform.identity
					})
				})
			}
		}

		if imageName != nil {
			messageImageView?.vectorImage = Theme.shared.tvgImage(for: imageName!)
		}
		if title != nil {
			messageTitleLabel?.text = title!
		}
		if message != nil {
			messageMessageLabel?.text = message!
		}
	}

	@objc func rotated() {
		render()
	}

	open func render() {
		switch UIScreen.main.traitCollection.verticalSizeClass {
		case .regular:
			NSLayoutConstraint.deactivate(compactConstraints)
			NSLayoutConstraint.activate(regularConstraints)
		case .compact:
			NSLayoutConstraint.deactivate(regularConstraints)
			NSLayoutConstraint.activate(compactConstraints)
		default:
			break
		}
	}

	@objc func keyboardWillShow(notification: Notification) {
		let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
		keyboardHeight = keyboardSize?.height ?? 0

		if self.composeViewBottomConstraint != nil {
			self.composeViewBottomConstraint.constant = self.mainView.safeAreaInsets.bottom - keyboardHeight

			UIView.animate(withDuration: 0.5) {
				self.mainView.layoutIfNeeded()
			}
		}
	}

	@objc func keyboardWillHide(notification: Notification) {
		if self.composeViewBottomConstraint != nil {
			self.composeViewBottomConstraint.constant =  0

			UIView.animate(withDuration: 0.5) {
				self.mainView.layoutIfNeeded()
			}
		}
	}

}
