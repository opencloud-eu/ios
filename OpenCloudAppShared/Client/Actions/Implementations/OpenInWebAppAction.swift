//
//  OpenInWebAppAction.swift
//  OpenCloudAppShared
//
//  Created by Felix Schwarz on 06.09.22.
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
import OpenCloudApp

public extension OCClassSettingsKey {
	static let openInWebAppMode = OCClassSettingsKey("open-in-web-app-mode")
	static let inAppWebAppLinkOpenMode = OCClassSettingsKey("in-app-web-app-link-open-mode")
}

public enum OpenInWebAppActionMode: String {
	case auto = "auto"
	case defaultBrowser = "default-browser"
	case inApp = "in-app"
	case inAppWithDefaultBrowserOption = "in-app-with-default-browser-option"
}

public enum InAppWebAppLinkOpenMode: String {
	case withDefaultBrowser = "with-default-browser"
	case navigate = "navigate"
	case choice = "choice"
	case deny = "deny"
	case silentDeny = "silent-deny"
}

public class OpenInWebAppAction: Action {
	public static func registerSettings() {
		self.registerOCClassSettingsDefaults([
			.openInWebAppMode : OpenInWebAppActionMode.auto.rawValue,
			.inAppWebAppLinkOpenMode : InAppWebAppLinkOpenMode.withDefaultBrowser.rawValue
		], metadata: [
			.openInWebAppMode : [
				.type 		: OCClassSettingsMetadataType.string,
				.label		: "Open In WebApp mode",
				.description 	: "Determines how to open a document in a web app.",
				.status		: OCClassSettingsKeyStatus.advanced,
				.category	: "Actions",
				.possibleValues : [
					[
						OCClassSettingsMetadataKey.value 	: OpenInWebAppActionMode.auto.rawValue,
						OCClassSettingsMetadataKey.description 	: "Open using `\(OpenInWebAppActionMode.inAppWithDefaultBrowserOption.rawValue)`, unless the respective endpoint is not available - in which case `\(OpenInWebAppActionMode.defaultBrowser.rawValue)` is used instead. If no endpoint to open the document is available, an error message is shown."
					],
					[
						OCClassSettingsMetadataKey.value 	: OpenInWebAppActionMode.defaultBrowser.rawValue,
						OCClassSettingsMetadataKey.description 	: "Open in default browser app. May require user to sign in."
					],
					[
						OCClassSettingsMetadataKey.value 	: OpenInWebAppActionMode.inApp.rawValue,
						OCClassSettingsMetadataKey.description 	: "Open inline in an in-app browser."
					],
					[
						OCClassSettingsMetadataKey.value 	: OpenInWebAppActionMode.inAppWithDefaultBrowserOption.rawValue,
						OCClassSettingsMetadataKey.description 	: "Open inline in an in-app browser, but provide a button to open the document in the default browser (may require the user to sign in)."
					]
				]
			],

			.inAppWebAppLinkOpenMode : [
				.type 		: OCClassSettingsMetadataType.string,
				.label		: "In-app WebApp link open mode",
				.description 	: "Determines how to open links that an web app (presented in-app) wants to open in a new window.",
				.status		: OCClassSettingsKeyStatus.advanced,
				.category	: "Actions",
				.possibleValues : [
					[
						OCClassSettingsMetadataKey.value 	: InAppWebAppLinkOpenMode.withDefaultBrowser.rawValue,
						OCClassSettingsMetadataKey.description 	: "Opens the link in the default browser."
					],
					[
						OCClassSettingsMetadataKey.value 	: InAppWebAppLinkOpenMode.navigate.rawValue,
						OCClassSettingsMetadataKey.description 	: "Opens the link in the in-app browser, possibly navigating away from the WebApp."
					],
					[
						OCClassSettingsMetadataKey.value 	: InAppWebAppLinkOpenMode.choice.rawValue,
						OCClassSettingsMetadataKey.description 	: "Asks the user whether to open the link in the in-app browser or the default browser."
					],
					[
						OCClassSettingsMetadataKey.value 	: InAppWebAppLinkOpenMode.deny.rawValue,
						OCClassSettingsMetadataKey.description 	: "Denies opening the link and informs the user."
					],
					[
						OCClassSettingsMetadataKey.value 	: InAppWebAppLinkOpenMode.silentDeny.rawValue,
						OCClassSettingsMetadataKey.description 	: "Silently denies opening the link without bringing up an alert, logging that a link-opening was denied."
					]
				]
			]
		])
	}

	override public class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.opencloud.action.openinwebapp") }
	override public class var category : ActionCategory? { return .normal }
	override public class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreDetailItem, .contextMenuItem, .directOpen, .unviewableFileType] }
	override open class var keyCommand : String? { return "E" }
	override open class var keyModifierFlags: UIKeyModifierFlags? { return [.command, .shift] }

	class open func createActionExtension(for app: OCAppProviderApp, core: OCCore) -> ActionExtension {
		let objectProvider : OCExtensionObjectProvider = { (_ rawExtension, _ context, _ error) -> Any? in
			if let actionExtension = rawExtension as? ActionExtension,
				let actionContext   = context as? ActionContext {
				let action = self.init(for: actionExtension, with: actionContext)

				action.app = app

				return action
			}

			return nil
		}

		let appName = app.name ?? UUID().uuidString
		let extensionIdentifier = OCExtensionIdentifier("\(identifier!.rawValue).\(appName.lowercased())")
		let coreRunIdentifier = core.runIdentifier

		let standardMatcher = actionCustomContextMatcher
		let customMatcher : OCExtensionCustomContextMatcher  = { (context, priority) -> OCExtensionPriority in
			// Apply standard matching
			let standardPriority = standardMatcher(context, priority)

			guard standardPriority != .noMatch, let actionContext = context as? ActionContext else {
				return .noMatch
			}

			// Limit to specific core
			guard let core = actionContext.core, core.runIdentifier == coreRunIdentifier else {
				return .noMatch
			}

			// Apply app matching
			if self.applicablePosition(forContext: actionContext, app: app) == .none {
				return .noMatch
			}

			return standardPriority
		}

		return ActionExtension(name: OCLocalizedFormat("Open in {{appName}} (web)", ["appName" : appName]), category: category!, identifier: extensionIdentifier, locations: locations, features: features, objectProvider: objectProvider, customMatcher: customMatcher, keyCommand: nil, keyModifierFlags: nil)
	}

	class open func applicablePosition(forContext: ActionContext, app: OCAppProviderApp) -> ActionPosition {
		// OpenInWebApp only supports a single item
		guard let item = forContext.items.first, forContext.items.count == 1 else {
			return .none
		}

		// Exclude directories
		if item.type == .collection {
			return .none
		}

		// Ensure item is supported by the web app
		if !app.supportsItem(item) {
			return .none
		}

		// Tapping a file: only open the server's default app for it, and only if the app has no viewer for it
		if forContext.location?.identifier == .directOpen {
			guard let core = forContext.core, opensOnTap(item: item, app: app, core: core) else {
				return .none
			}

			return .first
		}

		return .nearFirst
	}

	class func opensOnTap(item: OCItem, app: OCAppProviderApp, core: OCCore) -> Bool {
		guard core.connectionStatus == .online, // Offline: keep showing the file, so it can still be opened in other apps
		      !item.locallyModified, !item.syncActivity.contains(.uploading), // The web app would open the server version, not the local changes
		      let mimeType = item.mimeType,
		      let defaultApp = defaultApp(for: item, core: core), defaultApp.name == app.name else {
			Log.debug("Open on tap skipped for \(app.name ?? "-"): online=\(core.connectionStatus == .online) locallyModified=\(item.locallyModified) syncActivity=\(item.syncActivity.rawValue) mimeType=\(item.mimeType ?? "-") defaultApp=\(defaultApp(for: item, core: core)?.name ?? "-")")
			return false
		}

		// Confidential mode: the web view has no watermark/screenshot protection, so don't make it the default way to open files
		if ConfidentialManager.shared.confidentialSettingsEnabled {
			Log.debug("Open on tap skipped for \(app.name ?? "-"): confidential mode")
			return false
		}

		// Viewers are only registered in the app itself
		let viewerType = OCExtensionType("app.viewer") // OCExtensionType.viewer, which is defined in the app target
		guard OCExtensionManager.shared.extensions.contains(where: { $0.type == viewerType }) else {
			return false
		}

		// Empty file (f.ex. just created): nothing to preview, so open it for editing
		if item.size == 0 {
			return true
		}

		let viewerLocation = OCExtensionLocation(ofType: viewerType, identifier: OCExtensionLocationIdentifier(rawValue: mimeType))
		let viewerContext = OCExtensionContext(location: viewerLocation, requirements: nil, preferences: nil)

		// No match returns nil, which Swift turns into a thrown error (DisplayHostViewController treats it as "no viewer" too)
		let viewers = (try? OCExtensionManager.shared.provideExtensions(for: viewerContext)) ?? []

		if !viewers.isEmpty {
			Log.debug("Open on tap skipped for \(app.name ?? "-"): viewer available for \(mimeType)")
		}

		return viewers.isEmpty
	}

	/// The app the server names as default for the item's type (by MIME type, then by file extension)
	public class func defaultApp(for item: OCItem, core: OCCore) -> OCAppProviderApp? {
		guard let types = core.appProvider?.types else {
			return nil
		}

		if let mimeType = item.mimeType?.lowercased(),
		   let type = types.first(where: { $0.mimeType?.lowercased() == mimeType && $0.defaultApp != nil }) {
			return type.defaultApp
		}

		if let fileExtension = item.name.map({ ($0 as NSString).pathExtension.lowercased() }), !fileExtension.isEmpty,
		   let type = types.first(where: { $0.extension?.lowercased() == fileExtension && $0.defaultApp != nil }) {
			return type.defaultApp
		}

		return nil
	}

	/// The web app action to use for an item: the server's default app for its type, else the first one
	public class func preferredAction(in actions: [Action], for item: OCItem, core: OCCore) -> OpenInWebAppAction? {
		let webAppActions = actions.compactMap { $0 as? OpenInWebAppAction }

		if let defaultAppName = defaultApp(for: item, core: core)?.name,
		   let defaultAppAction = webAppActions.first(where: { $0.app?.name == defaultAppName }) {
			return defaultAppAction
		}

		return webAppActions.first
	}

	public var app : OCAppProviderApp?

	// MARK: - Action implementation
	override public func run() {
		var openMode : OpenInWebAppActionMode = .auto

		if let openInWebAppMode = classSetting(forOCClassSettingsKey: .openInWebAppMode) as? String, let configuredOpenMode = OpenInWebAppActionMode(rawValue: openInWebAppMode) {
			openMode = configuredOpenMode
		}

		if let appProvider = context.core?.appProvider, openMode == .auto {
			if appProvider.supportsOpenDirect {
				if appProvider.supportsOpenInWeb {
					openMode = .inAppWithDefaultBrowserOption
				} else {
					openMode = .inApp
				}
			} else if appProvider.supportsOpenInWeb {
				openMode = .defaultBrowser
			}
		}

		if context.items.count == 1, let item = context.items.first, let core = context.core {
			core.updateLastUsed(for: item)
		}

		switch openMode {
			case .defaultBrowser:
				openInExternalBrowser()

			case .inApp:
				openInInAppBrowser(withDefaultBrowserOption: false)

			case .inAppWithDefaultBrowserOption:
				openInInAppBrowser(withDefaultBrowserOption: true)

			case .auto:
				// No open mode available, return error
				if let viewController = context.viewController, let item = context.items.first {
					let appName = self.app?.name ?? "app"
					let itemName = item.name ?? "item"

					let alertController = ThemedAlertController(
						with: OCLocalizedFormat("Error opening {{itemName}} in {{appName}}", ["itemName" : itemName, "appName" : appName]),
						message: OCLocalizedString("Opening documents is not supported by the app provider on this instance.", nil),
						okLabel: OCLocalizedString("OK", nil),
						action: nil)

					viewController.present(alertController, animated: true)
				}
		}
	}

	func openInInAppBrowser(withDefaultBrowserOption defaultBrowserOption: Bool) {
		guard context.items.count == 1, let item = context.items.first, let core = context.core, let viewController = context.viewController else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let doneHandler: ClientWebAppViewController.DoneHandler = { [weak core] webAppViewController in
			if let parentLocation = item.location?.parent {
				core?.scheduleUpdateScan(for: parentLocation, waitForNextQueueCycle: true)
			}
		}

		// Request the mobile view on phones and narrow iPad windows (only apps with one use it, f.ex. EuroOffice; like web, which asks below 640pt).
		// Decided once on opening: resizing the window later keeps the view.
		let traits = viewController.traitCollection
		let mobile = (traits.userInterfaceIdiom == .phone) || (traits.horizontalSizeClass == .compact)

		// Open in in-app browser
		core.connection.open(inApp: item, with: app, viewMode: nil, mobile: mobile, completionHandler: { (error, url, method, headers, parameters, urlRequest) in
			if let error {
				OnMainThread {
					let appName = self.app?.name ?? "app"
					let itemName = item.name ?? "item"

					let alertController = ThemedAlertController(
						with: OCLocalizedFormat("Error opening {{itemName}} in {{appName}}", ["itemName" : itemName, "appName" : appName]),
						message: error.localizedDescription,
						okLabel: OCLocalizedString("OK", nil),
						action: nil)

					viewController.present(alertController, animated: true)

					self.completed(with: error)
				}

				return
			}

			if let urlRequest = urlRequest as? URLRequest {
				OnMainThread {
					let webAppViewController = ClientWebAppViewController(with: urlRequest, doneHandler: doneHandler)
					webAppViewController.navigationItem.title = item.name

					// Collabora: embed it in a host page that handles its postMessages (falls back to loading urlRequest directly)
					if let appName = self.app?.name, appName.lowercased().hasPrefix("collabora"), method?.rawValue.uppercased() == "POST", let url, let parameters {
						webAppViewController.collaboraHostPage = CollaboraHostPage(appURL: url, formParameters: parameters as? [String:String] ?? [:], accountURL: core.bookmark.url)
					}

					if defaultBrowserOption {
						webAppViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(title: nil, image: OCSymbol.icon(forSymbolName: "safari"), primaryAction: UIAction(handler: { [weak webAppViewController] _ in
							webAppViewController?.parent?.dismiss(animated: true, completion: {
								self.openInExternalBrowser()
							})
						}), menu: nil)

						webAppViewController.openInBrowserHandler = { [weak webAppViewController] in
							webAppViewController?.parent?.dismiss(animated: true, completion: {
								self.openInExternalBrowser()
							})
						}
					}

					let navigationController = ThemeNavigationController(rootViewController: webAppViewController)
					navigationController.modalPresentationStyle = .overFullScreen // Fill the screen with the webapp on iPad

					self.context.viewController?.present(navigationController, animated: true)
				}
			}

			self.completed(with: error)
		})
	}

	func openInExternalBrowser() {
		guard context.items.count == 1, let item = context.items.first, let core = context.core else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		// Open in external browser
		core.connection.open(inWeb: item, with: app) { (inError, url) in
			var error = inError

			if let url = url {
				if !OCAuthenticationBrowserSessionCustomScheme.open(url) {  // calls UIApplication.shared.open where available. That API can't be called directly from extension-ready frameworks
					// openURL not available -> return an error
					error = NSError(ocError: .internal)
				}
			}

			self.completed(with: error)
		}
	}

	override public var position: ActionPosition {
		if let app = app {
			return type(of: self).applicablePosition(forContext: context, app: app)
		}

		return .none
	}

	override public var icon: UIImage? {
		if let remoteIcon = (app?.iconResourceRequest?.resource as? OCResourceImage)?.image?.image {
			let iconSize = CGSize(width: 32, height: 32)
			return remoteIcon.scaledImageFitting(in: iconSize).paddedTo(width: iconSize.width, height: iconSize.height)
		}

		return super.icon
	}

	override public class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return OCSymbol.icon(forSymbolName: "globe")
	}
}
