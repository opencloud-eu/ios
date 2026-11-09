//
//  BrowserNavigationViewController.swift
//  OpenCloudAppShared
//
//  Created by Felix Schwarz on 16.01.23.
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
import OpenCloudSDK

public protocol BrowserNavigationViewControllerDelegate: AnyObject {
	func browserNavigation(viewController: BrowserNavigationViewController, contentViewControllerDidChange: UIViewController?)
}

private class BrowserContentContainerView: UIView {
	weak var browserNavigationViewController: BrowserNavigationViewController?

	override func accessibilityPerformEscape() -> Bool {
		guard let browserNavigationViewController, browserNavigationViewController.history.canMoveBack else {
			return false
		}

		browserNavigationViewController.moveBack()

		return true
	}
}

private struct BrowserContentTransition {
	let token: UUID
	let outgoingViewController: UIViewController
	let outgoingView: UIView
	let outgoingViewWasUserInteractionEnabled: Bool
	let outgoingViewWasAccessibilityElementsHidden: Bool
	let incomingView: UIView
	let animator: UIViewPropertyAnimator
}

open class BrowserNavigationViewController: EmbeddingViewController, Themeable, BrowserNavigationHistoryDelegate, ThemeCSSAutoSelector {
	var navigationView: UINavigationBar = UINavigationBar()
	var contentContainerView: UIView = BrowserContentContainerView()
	var contentContainerLidView: UIView = UIView()

	var sideBarSeperatorView: ThemeCSSView = ThemeCSSView(withSelectors: [.separator])

	lazy open var history: BrowserNavigationHistory = {
		let history = BrowserNavigationHistory()
		history.delegate = self
		return history
	}()

	weak open var delegate: BrowserNavigationViewControllerDelegate?

	open override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		updateSwipeNavigationEdges()

		if let windowWidth = view.window?.bounds.width {
			if preferredSideBarWidth > windowWidth {
				// Adapt to widths slimmer than sidebarWidth
				sideBarWidth = windowWidth - 20
			} else {
				// Use preferredSideBarWidth
				sideBarWidth = preferredSideBarWidth
			}

			if windowWidth < sideBarWidth * 2.5 {
				// Slide the sidebar over the content if the content doesn't have at least 2.5x the space of the sidebar
				sideBarDisplayMode = .over
			} else {
				// Show sidebar and content side by side if there's enough space
				sideBarDisplayMode = .sideBySide
			}
		} else {
			// Slide the sidebar over the content
			// if the window width can't be determined
			sideBarDisplayMode = .over
		}
	}

	open override func viewDidLoad() {
		super.viewDidLoad()

		contentContainerView.cssSelector = .content
		contentContainerView.translatesAutoresizingMaskIntoConstraints = false
		contentContainerView.focusGroupIdentifier = "com.opencloud.content"
		contentContainerView.clipsToBounds = true
		(contentContainerView as? BrowserContentContainerView)?.browserNavigationViewController = self

		let wrappedContentContainerView = contentContainerView.withScreenshotProtection
		view.addSubview(wrappedContentContainerView)

		navigationView.translatesAutoresizingMaskIntoConstraints = false
		navigationView.delegate = self

		contentContainerView.addSubview(navigationView)

		contentContainerLidView.translatesAutoresizingMaskIntoConstraints = false
		contentContainerLidView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
		contentContainerLidView.isHidden = true
		contentContainerLidView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showHideSideBar)))
		view.addSubview(contentContainerLidView)

		sideBarSeperatorView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(sideBarSeperatorView)

		navigationBarTopConstraint = navigationBarTopConstraint(for: navigationBarHidden)

		NSLayoutConstraint.activate([
			wrappedContentContainerView.topAnchor.constraint(equalTo: view.topAnchor),
			wrappedContentContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			wrappedContentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).with(priority: .defaultHigh), // Allow for flexibility without having to remove this constraint. It will be overridden by constraints with higher priority (default is .required) when necessary
			wrappedContentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

			contentContainerLidView.topAnchor.constraint(equalTo: wrappedContentContainerView.topAnchor),
			contentContainerLidView.bottomAnchor.constraint(equalTo: wrappedContentContainerView.bottomAnchor),
			contentContainerLidView.leadingAnchor.constraint(equalTo: wrappedContentContainerView.leadingAnchor),
			contentContainerLidView.trailingAnchor.constraint(equalTo: wrappedContentContainerView.trailingAnchor),

			sideBarSeperatorView.topAnchor.constraint(equalTo: wrappedContentContainerView.topAnchor),
			sideBarSeperatorView.bottomAnchor.constraint(equalTo: wrappedContentContainerView.bottomAnchor),
			sideBarSeperatorView.leadingAnchor.constraint(equalTo: wrappedContentContainerView.leadingAnchor, constant: -1),
			sideBarSeperatorView.widthAnchor.constraint(equalToConstant: 1),

			navigationBarTopConstraint!,
			navigationView.leadingAnchor.constraint(equalTo: contentContainerView.safeAreaLayoutGuide.leadingAnchor),
			navigationView.trailingAnchor.constraint(equalTo: contentContainerView.safeAreaLayoutGuide.trailingAnchor)
		])

		navigationView.items = [
		]

		setupSwipeNavigationGestureRecognizers()
	}

	private var _themeRegistered = false
	open override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if !_themeRegistered {
			_themeRegistered = true
			Theme.shared.register(client: self, applyImmediately: true)
		}
	}

	open override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		navigationController?.isNavigationBarHidden = true
	}

	open override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		endActiveContentTransition()
	}

	// MARK: - Navigation Bar
	private var navigationBarTopConstraint: NSLayoutConstraint?
	private func navigationBarTopConstraint(for hidden: Bool) -> NSLayoutConstraint {
		if hidden {
			return navigationView.bottomAnchor.constraint(equalTo: contentContainerView.topAnchor)
		}

		return navigationView.topAnchor.constraint(equalTo: contentContainerView.safeAreaLayoutGuide.topAnchor)
	}

	open var navigationBarHidden: Bool = false
	open func setNavigationBarHidden(_ hidden: Bool, animated: Bool, completion: (() -> Void)? = nil) {
		navigationBarHidden = hidden

		let updateLayout = {
			self.navigationBarTopConstraint?.isActive = false
			self.navigationBarTopConstraint = self.navigationBarTopConstraint(for: hidden)
			self.navigationBarTopConstraint?.isActive = true
		}

		OnMainThread(inline: true) {
			if animated {
				UIView.animate(withDuration: 0.3, animations: {
					updateLayout()
					self.view.layoutIfNeeded()
				}, completion: { _ in
					completion?()
				})
			} else {
				updateLayout()
				completion?()
			}
		}
	}

	// MARK: - Push & Navigation
	open func push(viewController: UIViewController, completion: BrowserNavigationHistory.CompletionHandler? = nil) {
		push(item: BrowserNavigationItem(viewController: viewController), completion: completion)
	}

	open func push(item: BrowserNavigationItem, completion: BrowserNavigationHistory.CompletionHandler? = nil) {
		// Push to history (+ present)
		history.push(item: item)

		if hideSideBarInOverDisplayModeOnPush, sideBarDisplayMode == .over {
			setSideBarVisible(false, animated: true)
		}
	}

	open func moveBack(completion: BrowserNavigationHistory.CompletionHandler? = nil) {
		history.moveBack(completion: completion)
	}

	open func moveForward(completion: BrowserNavigationHistory.CompletionHandler? = nil) {
		history.moveForward(completion: completion)
	}

	// MARK: - View Controller presentation
	open override func addContentViewControllerSubview(_ contentViewControllerView: UIView) {
		contentContainerView.insertSubview(contentViewControllerView, at: 0)
	}

	open override func constraintsForEmbedding(contentViewController: UIViewController) -> [NSLayoutConstraint] {
		if let contentView = contentViewController.view {
			return [
				contentView.topAnchor.constraint(equalTo: navigationView.bottomAnchor),
				contentView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
				contentView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
				contentView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor)
			]
		}

		return []
	}

	@objc func showHideSideBar() {
		setSideBarVisible(!isSideBarVisible)
	}

	@objc func navBack() {
		moveBack()
	}

	@objc func navForward() {
		moveForward()
	}

	func buildSideBarToggleBarButtonItem() -> UIBarButtonItem {
		let buttonItem = UIBarButtonItem(image: OCSymbol.icon(forSymbolName: "sidebar.leading"), style: .plain, target: self, action: #selector(showHideSideBar))
		buttonItem.tag = BarButtonTags.showHideSideBar.rawValue
		buttonItem.accessibilityLabel = OCLocalizedString("Show/Hide sidebar", nil)
		return buttonItem
	}

	private enum BarButtonTags: Int {
		case mask = 0xC0FFEE0
		case showHideSideBar
		case backButton
		case forwardButton
	}

	func updateLeftBarButtonItems(for navigationItem: UINavigationItem, withToggleSideBar: Bool = false, withBackButton: Bool = false, withForwardButton: Bool = false) {
		let (_, existingItems) = navigationItem.navigationContent.items(withIdentifier: "browser-navigation-left")

		func reuseOrBuild(_ tag: BarButtonTags, _ build: () -> UIBarButtonItem) -> UIBarButtonItem {
			for barButtonItem in existingItems {
				if barButtonItem.tag == tag.rawValue {
					return barButtonItem
				}
			}

			return build()
		}

		var leadingButtons : [UIBarButtonItem] = []
		var sidebarButtons : [UIBarButtonItem] = []

		if withToggleSideBar {
			let item = reuseOrBuild(.showHideSideBar, {
				return buildSideBarToggleBarButtonItem()
			})

			sidebarButtons.append(item)
		}

		if withBackButton {
			let item = reuseOrBuild(.backButton, {
				let backButtonItem = UIBarButtonItem(image: OCSymbol.icon(forSymbolName: "chevron.backward"), style: .plain, target: self, action: #selector(navBack))
				backButtonItem.tag = BarButtonTags.backButton.rawValue
				backButtonItem.accessibilityLabel = OCLocalizedString("Back", nil)

				return backButtonItem
			})

			item.isEnabled = history.canMoveBack

			leadingButtons.append(item)
		}

		if withForwardButton {
			let item = reuseOrBuild(.forwardButton, {
				let forwardButtonItem = UIBarButtonItem(image: OCSymbol.icon(forSymbolName: "chevron.forward"), style: .plain, target: self, action: #selector(navForward))
				forwardButtonItem.tag = BarButtonTags.forwardButton.rawValue
				forwardButtonItem.accessibilityLabel = OCLocalizedString("Forward", nil)

				return forwardButtonItem
			})

			item.isEnabled = history.canMoveForward

			leadingButtons.append(item)
		}

		let sideBarItem = NavigationContentItem(identifier: "browser-navigation-left", area: .left, priority: .standard, position: .leading, items: sidebarButtons)
		sideBarItem.visibleInPriorities = [ .standard, .high, .highest ]

		navigationItem.navigationContent.add(items: [
			sideBarItem,
			NavigationContentItem(identifier: "browser-navigation-left", area: .left, priority: .standard, position: .leading, items: leadingButtons)
		])
	}

	func updateContentNavigationItems() {
		if let contentNavigationItem = contentViewController?.navigationItem {
			updateLeftBarButtonItems(for: contentNavigationItem, withToggleSideBar: (effectiveSideBarDisplayMode == .sideBySide) ? !isSideBarVisible : true, withBackButton: true, withForwardButton: true)
		}

		updateSideBarNavigationItem()
	}

	// MARK: - BrowserNavigationHistoryDelegate
	public func present(item: BrowserNavigationItem?, with direction: BrowserNavigationHistory.Direction, completion: BrowserNavigationHistory.CompletionHandler?) {
		let needsSideBarLayout = (((item != nil) && (contentViewController == nil)) || ((item == nil) && (contentViewController != nil))) && (emptyHistoryBehaviour == .expandSideBarToFullWidth)

		endActiveContentTransition()

		let outgoingViewController = contentViewController
		let outgoingView = (outgoingViewController?.isViewLoaded == true) ? outgoingViewController?.view : nil
		let outgoingFrame = outgoingView?.frame ?? .zero
		let animateTransition = shouldAnimateContentTransition(direction: direction, item: item, outgoingViewController: outgoingViewController, needsSideBarLayout: needsSideBarLayout)

		if let item {
			// Has content
			let itemViewController = item.viewController

			contentViewController = itemViewController

			if let navigationItem = itemViewController?.navigationItem {
				updateContentNavigationItems()

				navigationView.items = [ navigationItem ]
			}
		} else {
			// Has no content
			contentViewController = nil
		}

		if navigationBarHidden {
			setNavigationBarHidden(false, animated: false)
		}

		self.view.layoutIfNeeded()

		if animateTransition, let outgoingViewController, let outgoingView {
			startContentTransition(direction: direction, outgoingViewController: outgoingViewController, outgoingView: outgoingView, outgoingFrame: outgoingFrame)
		}

		if item != nil, view.window != nil {
			UIAccessibility.post(notification: .screenChanged, argument: nil)
		}

		let done = {
			self.delegate?.browserNavigation(viewController: self, contentViewControllerDidChange: self.contentViewController)
			completion?(true)
		}

		if needsSideBarLayout {
			OnMainThread {
				UIView.animate(withDuration: 0.3, animations: {
					self.updateSideBarLayoutAndAppearance()
					self.view.layoutIfNeeded()
				}, completion: { _ in
					done()
				})
			}
		} else {
			done()
		}
	}

	// MARK: - Content transition
	private static let contentTransitionDuration: TimeInterval = 0.3
	private static let contentTransitionParallaxFraction: CGFloat = 0.3

	private var activeContentTransition: BrowserContentTransition?

	private func shouldAnimateContentTransition(direction: BrowserNavigationHistory.Direction, item: BrowserNavigationItem?, outgoingViewController: UIViewController?, needsSideBarLayout: Bool) -> Bool {
		guard direction != .none, item != nil, !needsSideBarLayout else {
			return false
		}

		guard let outgoingViewController, outgoingViewController.isViewLoaded, isViewLoaded, view.window != nil else {
			return false
		}

		guard history.item(for: outgoingViewController) != nil else {
			return false
		}

		if UIAccessibility.isReduceMotionEnabled, !UIAccessibility.prefersCrossFadeTransitions {
			return false
		}

		return true
	}

	private func startContentTransition(direction: BrowserNavigationHistory.Direction, outgoingViewController: UIViewController, outgoingView: UIView, outgoingFrame: CGRect) {
		let width = contentContainerView.bounds.width

		guard let incomingView = contentViewController?.view, incomingView !== outgoingView, width > 0 else {
			return
		}

		let isForward = (direction == .toNext)

		var sign: CGFloat = isForward ? 1.0 : -1.0

		if view.effectiveUserInterfaceLayoutDirection == .rightToLeft {
			sign = -sign
		}

		let parallax = width * BrowserNavigationViewController.contentTransitionParallaxFraction
		let incomingStartX = isForward ? (sign * width) : (sign * parallax)
		let outgoingEndX = isForward ? (-sign * parallax) : (-sign * width)

		let outgoingViewWasUserInteractionEnabled = outgoingView.isUserInteractionEnabled
		let outgoingViewWasAccessibilityElementsHidden = outgoingView.accessibilityElementsHidden

		outgoingView.translatesAutoresizingMaskIntoConstraints = true
		outgoingView.frame = outgoingFrame
		outgoingView.isUserInteractionEnabled = false
		outgoingView.accessibilityElementsHidden = true

		if isForward {
			contentContainerView.insertSubview(outgoingView, belowSubview: incomingView)
		} else {
			contentContainerView.insertSubview(outgoingView, aboveSubview: incomingView)
		}

		let animator = UIViewPropertyAnimator(duration: BrowserNavigationViewController.contentTransitionDuration, curve: .easeInOut)

		if UIAccessibility.prefersCrossFadeTransitions {
			incomingView.transform = .identity
			outgoingView.transform = .identity
			incomingView.alpha = 0.0

			animator.addAnimations {
				incomingView.alpha = 1.0
				outgoingView.alpha = 0.0
			}
		} else {
			incomingView.alpha = 1.0
			outgoingView.alpha = 1.0
			incomingView.transform = CGAffineTransform(translationX: incomingStartX, y: 0.0)
			outgoingView.transform = .identity

			animator.addAnimations {
				incomingView.transform = .identity
				outgoingView.transform = CGAffineTransform(translationX: outgoingEndX, y: 0.0)
			}
		}

		let token = UUID()

		activeContentTransition = BrowserContentTransition(token: token, outgoingViewController: outgoingViewController, outgoingView: outgoingView, outgoingViewWasUserInteractionEnabled: outgoingViewWasUserInteractionEnabled, outgoingViewWasAccessibilityElementsHidden: outgoingViewWasAccessibilityElementsHidden, incomingView: incomingView, animator: animator)

		animator.addCompletion { [weak self] _ in
			guard let self, self.activeContentTransition?.token == token else {
				return
			}

			self.endActiveContentTransition()
		}

		animator.startAnimation()
	}

	private func endActiveContentTransition() {
		guard let transition = activeContentTransition else {
			return
		}

		activeContentTransition = nil

		if transition.animator.state == .active {
			transition.animator.stopAnimation(true)
		}

		for animatedView in [transition.outgoingView, transition.incomingView] {
			animatedView.layer.removeAllAnimations()
			animatedView.transform = .identity
			animatedView.alpha = 1.0
		}

		transition.outgoingView.isUserInteractionEnabled = transition.outgoingViewWasUserInteractionEnabled
		transition.outgoingView.accessibilityElementsHidden = transition.outgoingViewWasAccessibilityElementsHidden
		transition.outgoingView.removeFromSuperview()
	}

	// MARK: - Swipe navigation
	private static let swipeNavigationMinimumTravelFraction: CGFloat = 0.3
	private static let swipeNavigationMinimumVelocity: CGFloat = 400.0

	private var backSwipeGestureRecognizer: UIScreenEdgePanGestureRecognizer?
	private var forwardSwipeGestureRecognizer: UIScreenEdgePanGestureRecognizer?
	private var appliedSwipeNavigationLayoutDirection: UIUserInterfaceLayoutDirection?

	private var canRevealSideBarBySwipe: Bool {
		return (sidebarViewController != nil) && !isSideBarVisible
	}

	private func setupSwipeNavigationGestureRecognizers() {
		func makeGestureRecognizer() -> UIScreenEdgePanGestureRecognizer {
			let gestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipeNavigation(_:)))
			gestureRecognizer.delegate = self

			contentContainerView.addGestureRecognizer(gestureRecognizer)

			return gestureRecognizer
		}

		backSwipeGestureRecognizer = makeGestureRecognizer()
		forwardSwipeGestureRecognizer = makeGestureRecognizer()

		updateSwipeNavigationEdges()
	}

	private func updateSwipeNavigationEdges() {
		let layoutDirection = view.effectiveUserInterfaceLayoutDirection

		guard appliedSwipeNavigationLayoutDirection != layoutDirection else {
			return
		}

		appliedSwipeNavigationLayoutDirection = layoutDirection

		let isRightToLeft = (layoutDirection == .rightToLeft)

		backSwipeGestureRecognizer?.edges = isRightToLeft ? .right : .left
		forwardSwipeGestureRecognizer?.edges = isRightToLeft ? .left : .right
	}

	@objc private func handleSwipeNavigation(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
		let isBackSwipe = (gestureRecognizer === backSwipeGestureRecognizer)

		guard gestureRecognizer.state == .ended, isBackSwipe || (gestureRecognizer === forwardSwipeGestureRecognizer) else {
			return
		}

		let isRightToLeft = (view.effectiveUserInterfaceLayoutDirection == .rightToLeft)
		let sign: CGFloat = (isBackSwipe != isRightToLeft) ? 1.0 : -1.0

		let travel = gestureRecognizer.translation(in: contentContainerView).x * sign
		let velocity = gestureRecognizer.velocity(in: contentContainerView).x * sign
		let requiredTravel = contentContainerView.bounds.width * BrowserNavigationViewController.swipeNavigationMinimumTravelFraction

		guard travel > requiredTravel || velocity > BrowserNavigationViewController.swipeNavigationMinimumVelocity else {
			return
		}

		if !isBackSwipe {
			moveForward()
		} else if history.canMoveBack {
			moveBack()
		} else if canRevealSideBarBySwipe {
			setSideBarVisible(true)
		}
	}

	// MARK: - Sidebar View Controller
	func updateSideBarNavigationItem() {
		var sideBarNavigationItem: UINavigationItem?

		if let sidebarViewController {
			// Add show/hide sidebar button to sidebar left items
			if let navigationController = sidebarViewController as? UINavigationController {
				sideBarNavigationItem = navigationController.topViewController?.navigationItem
			} else {
				sideBarNavigationItem = sidebarViewController.navigationItem
			}
		}

		if let sideBarNavigationItem {
			updateLeftBarButtonItems(for: sideBarNavigationItem, withToggleSideBar: (effectiveSideBarDisplayMode != .fullWidth))
		}
	}

	open var sidebarViewController: UIViewController? {
		willSet {
			sidebarViewController?.willMove(toParent: nil)
			sidebarViewController?.view.removeFromSuperview()
			sidebarViewController?.removeFromParent()
		}
		didSet {
			if let sidebarViewController, let sidebarViewControllerView = sidebarViewController.view {
				sidebarViewController.focusGroupIdentifier = "com.opencloud.sidebar"

				updateSideBarNavigationItem()

				addChild(sidebarViewController)
				view.addSubview(sidebarViewControllerView)
				sidebarViewControllerView.translatesAutoresizingMaskIntoConstraints = false
				updateSideBarLayoutAndAppearance()
				sidebarViewController.didMove(toParent: self)
			} else {
				updateSideBarLayoutAndAppearance()
			}
		}
	}

	// MARK: - Constraints, state & animation
	private var composedConstraints : [NSLayoutConstraint]? {
		willSet {
			if let composedConstraints {
				NSLayoutConstraint.deactivate(composedConstraints)
			}
		}
		didSet {
			if let composedConstraints {
				NSLayoutConstraint.activate(composedConstraints)
			}
		}
	}

	public enum SideBarDisplayMode {
		case fullWidth
		case sideBySide
		case over
	}

	public enum EmptyHistoryBehaviour {
		case none
		case expandSideBarToFullWidth
		case showEmptyHistoryViewController
	}

	public var isSideBarVisible: Bool = true {
		didSet {
			setNeedsStatusBarAppearanceUpdate()
		}
	}
	public var preferredSideBarWidth: CGFloat = 320
	var sideBarWidth: CGFloat = 320
	var preferredSideBarDisplayMode: SideBarDisplayMode?
	var sideBarDisplayMode: SideBarDisplayMode = .over {
		didSet {
			updateSideBarLayoutAndAppearance()
		}
	}

	var effectiveSideBarDisplayMode: SideBarDisplayMode {
		if history.isEmpty, emptyHistoryBehaviour == .expandSideBarToFullWidth {
			return .fullWidth
		}

		return sideBarDisplayMode
	}

	public var emptyHistoryBehaviour: EmptyHistoryBehaviour = .expandSideBarToFullWidth
	public var hideSideBarInOverDisplayModeOnPush: Bool = true

	open func setSideBarVisible(_ sideBarVisible: Bool, animated: Bool = true) {
		if isSideBarVisible == sideBarVisible {
			return
		}

		isSideBarVisible = sideBarVisible

		if animated {
			self.updateSideBarLayoutAndAppearance()

			if sideBarVisible {
				switch self.effectiveSideBarDisplayMode {
					case .over:
						self.contentContainerLidView.alpha = 0.0
						self.contentContainerLidView.isHidden = false
					default: break
				}
			}

			UIView.animate(withDuration: 0.25, animations: {
				if sideBarVisible {
					switch self.effectiveSideBarDisplayMode {
						case .over:
							self.contentContainerLidView.alpha = 1.0
						default: break
					}
				} else {
					self.contentContainerLidView.alpha = 0.0
				}
				self.sidebarViewController?.view.layoutIfNeeded()
				self.view.layoutIfNeeded()
			}, completion: { _ in
				if !sideBarVisible {
					self.contentContainerLidView.isHidden = true
				}
			})
		} else {
			updateSideBarLayoutAndAppearance()
		}
	}

	func updateSideBarLayoutAndAppearance() {
		var newConstraints : [NSLayoutConstraint] = []

		if let sidebarViewController, let sidebarView = sidebarViewController.view, let view {
			if isSideBarVisible {
				switch effectiveSideBarDisplayMode {
					case .fullWidth:
						// Sidebar occupies full area
						newConstraints = [
							sidebarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
							sidebarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
							sidebarView.topAnchor.constraint(equalTo: view.topAnchor),
							sidebarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
						]

						contentContainerLidView.isHidden = true

					case .sideBySide:
						// Sidebar + Content side-by-side
						newConstraints = [
							sidebarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
							sidebarView.trailingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: -1),
							sidebarView.topAnchor.constraint(equalTo: view.topAnchor),
							sidebarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
							sidebarView.widthAnchor.constraint(equalToConstant: sideBarWidth)
						]

						contentContainerLidView.isHidden = true

					case .over:
						// Sidebar over content
						newConstraints = [
							sidebarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
							sidebarView.topAnchor.constraint(equalTo: view.topAnchor),
							sidebarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
							sidebarView.widthAnchor.constraint(equalToConstant: sideBarWidth)
						]

						contentContainerLidView.isHidden = false
				}
			} else {
				// Position sidebar left outside of view
				newConstraints = [
					sidebarView.trailingAnchor.constraint(equalTo: view.leadingAnchor),
					sidebarView.topAnchor.constraint(equalTo: view.topAnchor),
					sidebarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
					sidebarView.widthAnchor.constraint(equalToConstant: sideBarWidth)
				]
			}
		}

		updateContentNavigationItems()

		composedConstraints = newConstraints
	}

	// MARK: - Themeing
	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		navigationView.applyThemeCollection(collection)
		view.apply(css: collection.css, properties: [.fill])
	}

	public var cssAutoSelectors: [ThemeCSSSelector] = [.splitView]

	// MARK: - Status Bar style
	open override var preferredStatusBarStyle: UIStatusBarStyle {
		var statusBarStyle: UIStatusBarStyle?

		if isSideBarVisible, let sidebarViewController {
			statusBarStyle = Theme.shared.activeCollection.css.getStatusBarStyle(for: sidebarViewController)
		} else if let contentViewController {
			statusBarStyle = Theme.shared.activeCollection.css.getStatusBarStyle(for: contentViewController)
		}

		if statusBarStyle == nil {
			statusBarStyle = Theme.shared.activeCollection.css.getStatusBarStyle(for: self)
		}

		return statusBarStyle ?? super.preferredStatusBarStyle
	}

	open override var childForStatusBarStyle: UIViewController? {
		return nil
	}
}

extension BrowserNavigationViewController: UINavigationBarDelegate {
	public func position(for bar: UIBarPositioning) -> UIBarPosition {
		return .topAttached
	}
}

extension BrowserNavigationViewController: UIGestureRecognizerDelegate {
	public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		let isBackSwipe = (gestureRecognizer === backSwipeGestureRecognizer)
		let isForwardSwipe = (gestureRecognizer === forwardSwipeGestureRecognizer)

		guard isBackSwipe || isForwardSwipe else {
			return true
		}

		guard contentContainerLidView.isHidden, activeContentTransition == nil else {
			return false
		}

		return isBackSwipe ? (history.canMoveBack || canRevealSideBarBySwipe) : history.canMoveForward
	}

	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		guard (gestureRecognizer === backSwipeGestureRecognizer) || (gestureRecognizer === forwardSwipeGestureRecognizer) else {
			return false
		}

		return otherGestureRecognizer is UIPanGestureRecognizer
	}
}

public extension UIViewController {
	var browserNavigationViewController: BrowserNavigationViewController? {
		var viewController: UIViewController? = self

		while viewController != nil {
			if let browserNavigationViewController = viewController as? BrowserNavigationViewController {
				return browserNavigationViewController
			}

			viewController = viewController?.parent
		}

		return nil
	}
}
