//
//  CardPresentationController.swift
//  OpenCloud
//
//  Created by Pablo Carrascal on 25/07/2018.
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

import Foundation
import UIKit
import OpenCloudSDK

private enum CardPosition {
	case half
	case open

	var heightMultiplier: CGFloat {
		switch self {
			case .half: return 0.58
			case .open: return 0.9
		}
	}
}

public protocol CardPresentationSizing : UIViewController {
	func cardPresentationSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize

	var fitsOnScreen : Bool { get set }
}

class DragView: UIView {
	// Increase the tap area of this view
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		return bounds.insetBy(dx: -20, dy: -10).contains(point)
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		let newRect = UIAccessibility.convertToScreenCoordinates(bounds.insetBy(dx: -20, dy: -10), in: self)
		self.accessibilityFrame = newRect
	}
}

final class CardPresentationController: UIPresentationController, Themeable {

	// MARK: - Instance Variables.
	private var cardPosition: CardPosition = .open

	private var cardAnimator: UIViewPropertyAnimator?
	private var cardPanGestureRecognizer : UIPanGestureRecognizer?

	private var dimmingView = UIView()
	private var dimmingViewGestureRecognizer : UITapGestureRecognizer?
	private var overStretchView = UIView()
	private var dragHandleView = DragView()

	private var cachedFittingSize : CGSize?
	private var presentedViewFittingSize : CGSize? {
		if cachedFittingSize == nil {
			maxWidthConstraint?.constant = self.maxWidth

			if let cardViewController = presentedViewController as? CardPresentationSizing {
				cachedFittingSize = cardViewController.cardPresentationSizeFitting(CGSize(width: maxWidth, height: UIView.layoutFittingExpandedSize.height), withHorizontalFittingPriority: UILayoutPriority(999), verticalFittingPriority: .defaultHigh)
			} else {
				cachedFittingSize = presentedView?.systemLayoutSizeFitting(self.windowFrame.size, withHorizontalFittingPriority: UILayoutPriority(999), verticalFittingPriority: .defaultHigh)
			}

			let safeBottom : CGFloat = presentingViewController.view?.window?.safeAreaInsets.bottom ?? 0

			Log.log("safeBottom=\(safeBottom)")

			cachedFittingSize?.height += safeBottom
		}

		return cachedFittingSize
	}

	var maxWidth : CGFloat {
		var windowWidth = windowFrame.size.width

		if traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .compact {
			windowWidth -= 100
		} else if windowWidth > 600 {
			windowWidth = 540
		}

		return windowWidth
	}

	private var windowFrame: CGRect {
		if let window = UserInterfaceContext.shared.currentWindow {
			return window.bounds
		} else {
			return UIScreen.main.bounds
		}
	}

	override var frameOfPresentedViewInContainerView: CGRect {
		var originX: CGFloat = 0
		let presentedWidth: CGFloat = maxWidth
		var presentedHeight: CGFloat = windowFrame.height * CardPosition.open.heightMultiplier
		let fittingSize = presentedViewFittingSize

		originX = (windowFrame.width - presentedWidth) / 2

		if let fittingHeight = fittingSize?.height, presentedHeight > fittingHeight {
			presentedHeight = fittingHeight
		}

		let presentedFrame = CGRect(origin: CGPoint(x: originX, y: self.offset(for: cardPosition)), size: CGSize(width: presentedWidth, height: presentedHeight))

		return presentedFrame
	}

	var withHandle : Bool
	var dismissable : Bool

	private var maxWidthConstraint : NSLayoutConstraint?

	init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, withHandle : Bool, dismissable: Bool) {
		self.withHandle = withHandle
		self.dismissable = dismissable
		super.init(presentedViewController: presentedViewController, presenting: presentingViewController)

		Theme.shared.register(client: self, applyImmediately: true)

		presentedViewController.view.layer.cornerRadius = 10
		presentedViewController.view.layer.masksToBounds = true
		presentedViewController.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

		maxWidthConstraint = presentedViewController.view.widthAnchor.constraint(lessThanOrEqualToConstant: self.maxWidth)
		maxWidthConstraint?.isActive = true
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		overStretchView.backgroundColor = collection.css.getColor(.fill, selectors: [.grouped, .table], for:overStretchView)
		dragHandleView.backgroundColor = collection.css.getColor(.fill, selectors: [.separator], for:dragHandleView)
	}

	private func offset(for position: CardPosition, translatedBy: CGFloat = 0, allowOverStretch: Bool = false) -> CGFloat {
		let windowFrame = self.windowFrame
		var visibleCardHeight = windowFrame.height * position.heightMultiplier
		let fittingSize = self.presentedViewFittingSize

		if !allowOverStretch {
			visibleCardHeight -= translatedBy
		}

		if let fittingHeight = fittingSize?.height, visibleCardHeight > fittingHeight {
			visibleCardHeight = fittingHeight
		}

		if allowOverStretch {
			visibleCardHeight -= translatedBy
		}

		return windowFrame.height - visibleCardHeight
	}

	// MARK: - Presentation
	override func presentationTransitionWillBegin() {
		if let containerView = containerView {

			dimmingView.alpha = 0
			dimmingView.backgroundColor = .black

			containerView.addSubview(dimmingView)

			if let transitionCoordinator = self.presentingViewController.transitionCoordinator {
				transitionCoordinator.animate(alongsideTransition: { (_) in
					self.dimmingView.alpha = 0.7
				})
			}

			// Add drag view to presentedView as presentedView is not yet part of the view hierarchy, so we can't yet attach to it via Auto Layout
			if let hostView = presentedView, dragHandleView.superview == nil, withHandle {
				dragHandleView.translatesAutoresizingMaskIntoConstraints = false
				hostView.addSubview(dragHandleView)

				// Tapping the handle should dismiss the view
				dragHandleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissView)))

				dragHandleView.layer.cornerRadius = 2.5

				NSLayoutConstraint.activate([
					dragHandleView.topAnchor.constraint(equalTo: hostView.topAnchor, constant: 10),
					dragHandleView.centerXAnchor.constraint(equalTo: hostView.centerXAnchor),
					dragHandleView.widthAnchor.constraint(equalToConstant: 50),
					dragHandleView.heightAnchor.constraint(equalToConstant: 5)
				])

			}
		}
	}

	override func presentationTransitionDidEnd(_ completed: Bool) {
		cardAnimator = UIViewPropertyAnimator(duration: 0.6, dampingRatio: 0.8)
		cardAnimator?.isInterruptible = true

		cardPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(userDragged))
		cardPanGestureRecognizer?.delegate = self
		cardPanGestureRecognizer?.cancelsTouchesInView = true

		containerView?.addGestureRecognizer(cardPanGestureRecognizer!)

		if dismissable {
			dimmingViewGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissView))
			dimmingView.addGestureRecognizer(dimmingViewGestureRecognizer!)
		}

		if let presentedView = presentedView,
		   let containerView = containerView {
			overStretchView.translatesAutoresizingMaskIntoConstraints = false
			overStretchView.isUserInteractionEnabled = false

			containerView.insertSubview(overStretchView, aboveSubview: dimmingView)

			NSLayoutConstraint.activate([
				overStretchView.leftAnchor.constraint(equalTo: presentedView.leftAnchor),
				overStretchView.rightAnchor.constraint(equalTo: presentedView.rightAnchor),
				overStretchView.topAnchor.constraint(equalTo: presentedView.bottomAnchor),
				overStretchView.heightAnchor.constraint(equalTo: containerView.heightAnchor)
			])
		}

		dragHandleView.accessibilityTraits = [.button]
		dragHandleView.accessibilityLabel = OCLocalizedString("Close actions menu", nil)
		dragHandleView.isAccessibilityElement = true

		PointerEffect.install(on: dragHandleView, effectStyle: .hoverScaled)
	}

	// MARK: - Dismissal
	override func dismissalTransitionWillBegin() {
		if let gestureRecognizer = dimmingViewGestureRecognizer {
			dimmingView.removeGestureRecognizer(gestureRecognizer)
		}
		if let gestureRecognizer = cardPanGestureRecognizer {
			presentedView?.removeGestureRecognizer(gestureRecognizer)
		}

		if let transitionCoordinator = self.presentingViewController.transitionCoordinator {
			transitionCoordinator.animate(alongsideTransition: { (_) in
				self.dimmingView.alpha = 0.0
			})
		}
	}

	// MARK: - Layout
	private var animationOnGoing = false

	override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
		cachedFittingSize = nil
	}

	override func containerViewWillLayoutSubviews() {
		if cardPanGestureRecognizer?.state != .began, cardPanGestureRecognizer?.state != .changed, !animationOnGoing {
			let presentedViewFrame = frameOfPresentedViewInContainerView

			UIView.animate(withDuration: 0.15, animations: {
				self.presentedView?.frame = presentedViewFrame
			})
			self.dimmingView.frame = self.windowFrame

			if let cardViewController = presentedViewController as? CardPresentationSizing,
			   let fittingSize = presentedViewFittingSize {
				var fitsOnScreen : Bool = false

				fitsOnScreen = fittingSize.height < (windowFrame.size.height * CardPosition.open.heightMultiplier)

				cardViewController.fitsOnScreen = fitsOnScreen
			}
		}
	}

	override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
		super.willTransition(to: newCollection, with: coordinator)

		cachedFittingSize = nil
	}

	// MARK: - Card gesture handling
	@objc private func userDragged(_ gestureRecognizer: UIPanGestureRecognizer) {
		let velocity = gestureRecognizer.velocity(in: presentedView).y
		let newOffset = self.offset(for: cardPosition, translatedBy: gestureRecognizer.translation(in: presentedView).y, allowOverStretch: (gestureRecognizer.state != .ended))

		if newOffset >= 0 {
			switch gestureRecognizer.state {
			case .began, .changed:
				presentedView?.frame.origin.y = newOffset
			case .ended:
				animate(to: newOffset, with: velocity)
			default:
				()
			}
		} else {
			if gestureRecognizer.state == .ended {
				animate(to: newOffset, with: velocity)
			}
		}
	}

	// MARK: - Animation
	private func animate(to offset: CGFloat, with velocity: CGFloat) {
		let distanceFromBottom = windowFrame.height - offset
		var nextPosition: CardPosition = .open

		switch velocity {
			case _ where velocity >= 2000:
				if dismissable {
					dismissView()
				}

			case _ where velocity < 0:
				if distanceFromBottom > windowFrame.height * (CardPosition.open.heightMultiplier - 0.3) {
					nextPosition = .open
				} else if distanceFromBottom > windowFrame.height * (CardPosition.half.heightMultiplier - 0.1) {
					nextPosition = .half
				}

			case _ where velocity >= 0:
				if distanceFromBottom > windowFrame.height * (CardPosition.open.heightMultiplier - 0.1) {
					nextPosition = .open
				} else if distanceFromBottom > windowFrame.height * (CardPosition.half.heightMultiplier - 0.1) {
					nextPosition = .half
				} else if dismissable {
					dismissView()
				}

				default:
				()
		}

		cardAnimator?.stopAnimation(true)
		animationOnGoing = false

		cardAnimator?.addAnimations {
			self.presentedView?.frame.origin.y = self.offset(for: nextPosition)
			self.containerView?.layoutIfNeeded()
		}
		cardAnimator?.addCompletion({ (_) in
			self.animationOnGoing = false
		})

		animationOnGoing = true
		self.cardPosition = nextPosition
		cardAnimator?.startAnimation()
	}

	// MARK: - Dismissal
	@objc func dismissView() {
		self.presentedViewController.dismiss(animated: true)
	}
}

// MARK: - GestureRecognizer delegate
extension CardPresentationController: UIGestureRecognizerDelegate {

	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		if gestureRecognizer == cardPanGestureRecognizer {
			if let otherScrollView = otherGestureRecognizer.view as? UIScrollView,
			   otherScrollView.isScrollEnabled {
				return true
			}
		}

		return false
	}

	public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		let velocity = cardPanGestureRecognizer?.velocity(in: gestureRecognizer.view)

		var targetView = presentedView?.hitTest(gestureRecognizer.location(in: presentedView), with: nil)

		var scrollView : UIScrollView?

		while targetView != nil, targetView != containerView, scrollView == nil {
			if let foundScrollView = targetView as? UIScrollView {
				scrollView = foundScrollView
				break
			} else {
				targetView = targetView?.superview
			}
		}

		if scrollView != nil,
		   let contentOffsetY = scrollView?.contentOffset.y,
		   let hasVelocity = velocity,
		   cardPosition == .open {
			if contentOffsetY > 0, hasVelocity.y > 0 {
				return false
			}

			if hasVelocity.y < 0 {
				return false
			}
		}

		return true
	}
}

// MARK: - Convenience addition to UIViewController
extension UIViewController {
	public func present(asCard viewController: UIViewController, animated: Bool, withHandle: Bool = true, dismissable: Bool = true, completion: (() -> Void)? = nil) {
		let animator = CardTransitionDelegate(viewControllerToPresent: viewController, presentingViewController: self, withHandle: withHandle, dismissable: dismissable)

		viewController.transitioningDelegate = animator // .transitioningDelegate is only weak!
		viewController.modalPresentationStyle = .custom

		present(viewController, animated: animated, completion: {
			_ = animator // Keep reference to CardTransitionDelegate around (could be dropped prematurely otherwise)
			completion?()
		})
	}
}
