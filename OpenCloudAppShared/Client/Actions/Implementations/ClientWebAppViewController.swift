//
//  ClientWebAppViewController.swift
//  OpenCloudAppShared
//
//  Created by Felix Schwarz on 19.09.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://opencloud.eu/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import OpenCloudSDK
import WebKit

open class ClientWebAppViewController: UIViewController, WKUIDelegate, Themeable {
	public typealias DoneHandler = (ClientWebAppViewController) -> Void

	public var urlRequest: URLRequest
	public var webView: WKWebView?

	public var shouldSendCloseEvent: Bool = true

	public var doneHandler: DoneHandler?

	public init(with urlRequest: URLRequest, doneHandler: DoneHandler? = nil) {
		self.urlRequest = urlRequest
		self.doneHandler = doneHandler

		super.init(nibName: nil, bundle: nil)

		self.isModalInPresentation = true
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public var webViewConfiguration: WKWebViewConfiguration {
		let configuration = WKWebViewConfiguration()
		let webSiteDataStore = WKWebsiteDataStore.nonPersistent()

		configuration.websiteDataStore = webSiteDataStore
		configuration.applicationNameForUserAgent = "MobileSafari" // Needed for some web apps that will present the desktop UI otherwise (f.ex. OnlyOffice as of 2022-09-19)

		// A top-level page without a viewport tag is laid out 980pt wide and scaled down to fit. Web apps that
		// are wrapped in an iframe (f.ex. hosted Collabora: a relay page embeds the editor) then render at ~40% size,
		// as viewport tags inside iframes are ignored. Add a device-width viewport only where the page has none.
		let viewportScript = WKUserScript(source: """
			if (!document.querySelector('meta[name="viewport"]')) {
				document.head.insertAdjacentHTML('afterbegin', '<meta name="viewport" content="width=device-width, initial-scale=1">');
			}
			""", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
		configuration.userContentController.addUserScript(viewportScript)

		return configuration
	}

	override public func loadView() {
		let rootView = UIView()

		webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
		webView?.translatesAutoresizingMaskIntoConstraints = false
		webView?.uiDelegate = self

		#if DEBUG
		// Debug builds only: allow Safari's Web Inspector (Develop menu) to attach to web apps like Collabora
		if #available(iOS 16.4, *) {
			webView?.isInspectable = true
		}
		#endif

		rootView.addSubview(webView!)

		NSLayoutConstraint.activate([
			webView!.leadingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.leadingAnchor),
			webView!.trailingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.trailingAnchor),
			webView!.topAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.topAnchor),
			webView!.bottomAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.bottomAnchor)
		])

		view = rootView
	}

	override public func viewDidLoad() {
		super.viewDidLoad()

		Theme.shared.register(client: self, applyImmediately: true)

		navigationItem.rightBarButtonItem = UIBarButtonItem(title: nil, image: OCSymbol.icon(forSymbolName: "xmark.circle.fill"), primaryAction: UIAction(handler: { [weak self] _ in
			if self?.shouldSendCloseEvent == true {
				if let strongSelf = self {
					// Close via window.close(), which is calling dismissSecurely() once done
					strongSelf.closeWebWindow()

					// Call dismissOnce()
					strongSelf.dismissOnce({
						// Dispose after 10 seconds automatically (or earlier if web view signals close event)
						OnMainThread(after: 10) {
							strongSelf.disposeWebViewOnce()
						}
					})
				}
			} else {
				// Close directly
				self?.dismissOnce({ [weak self] in
					self?.disposeWebViewOnce()
				})
			}
		}))
	}

	override public func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		webView?.load(urlRequest)
	}

	override public func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		// Drop web view
		webView?.uiDelegate = nil
		webView?.removeFromSuperview()
		webView = nil

		doneHandler?(self)
		doneHandler = nil
	}

	private var isDismissed = false
	public func dismissOnce(_ completion: (() -> Void)? = nil) {
		if !isDismissed {
			isDismissed = true
			self.dismiss(animated: true, completion: completion)
		} else {
			completion?()
		}
	}

	private var hasDisposedWebView = false
	func disposeWebViewOnce() {
		if !hasDisposedWebView {
			hasDisposedWebView = true
			webView?.removeFromSuperview()
			webView = nil
		}
	}

	// window.close() handling
	public func closeWebWindow() {
		webView?.evaluateJavaScript("window.close();")
	}

	// Theme: web apps follow the app's light/dark style (via prefers-color-scheme), not the system's.
	// Set explicitly, as the theme's own override doesn't reach modals presented after it was applied.
	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		overrideUserInterfaceStyle = collection.css.getUserInterfaceStyle()
	}

	// UI delegate
	public func webViewDidClose(_ webView: WKWebView) {
		dismissOnce({ [weak self] in
			self?.disposeWebViewOnce()
		})
	}
}
