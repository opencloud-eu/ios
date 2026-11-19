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
import QuickLook
import UniformTypeIdentifiers

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

	public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
		if navigationAction.targetFrame == nil, let url = navigationAction.request.url,
		   let openModeRaw = OpenInWebAppAction.classSetting(forOCClassSettingsKey: .inAppWebAppLinkOpenMode) as? String,
		   let openMode = InAppWebAppLinkOpenMode(rawValue: openModeRaw) {
			// Web app wants to open a link in a new window
			var title: String
			var openAction, navigateAction: UIAlertAction?

			title = OCLocalizedString("Web app requests to open link", nil)
			openAction = UIAlertAction(title: OCLocalizedString("Open", nil), style: .default) { (_) in
				OCAuthenticationBrowserSessionCustomScheme.open(url) // Open in default browser
			}
			navigateAction = UIAlertAction(title: OCLocalizedString("Navigate", nil), style: .default) { (_) in
				webView.load(navigationAction.request) // Navigate
			}

			switch openMode {
				case .withDefaultBrowser:
					navigateAction = nil

				case .navigate:
					openAction = nil

				case .choice:
					// allow all actions
					break

				case .deny:
					title = OCLocalizedString("The web app attempted to open the URL below. Opening was denied by configuration.", nil)
					openAction = nil
					navigateAction = nil

				case .silentDeny:
					Log.debug("ClientWebAppViewController denied opening a link.")
					return nil
			}

			let alert = ThemedAlertController(title: title, message: url.absoluteString, preferredStyle: .alert)
			let cancelAction = UIAlertAction(title: OCLocalizedString("Cancel", nil), style: .cancel)

			if let openAction {
				alert.addAction(openAction)
			}
			if let navigateAction {
				alert.addAction(navigateAction)
			}
			alert.addAction(cancelAction)

			present(alert, animated: true)
		}

		return nil // nil -> do not open; webView -> open in originating webView (default)
	}

	override public func loadView() {
		let rootView = UIView()

		webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
		webView?.translatesAutoresizingMaskIntoConstraints = false
		webView?.uiDelegate = self
		webView?.navigationDelegate = downloadHandler

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

		// A download preview is presented as a sheet and shouldn't trigger this - but if it does, keep the web app
		if downloadHandler.isPresentingPreview, !isBeingDismissed, navigationController?.isBeingDismissed != true {
			return
		}

		// Drop downloads and web view
		downloadHandler.cancelAndCleanUp()
		webView?.navigationDelegate = nil
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
			if presentedViewController != nil, let presenting = (navigationController ?? self).presentingViewController {
				// Something is presented on top (f.ex. a download preview): self.dismiss() would only close that
				presenting.dismiss(animated: true, completion: completion)
			} else {
				self.dismiss(animated: true, completion: completion)
			}
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

	// Downloads
	private lazy var downloadHandler = DownloadHandler(viewController: self)
}

// MARK: - Downloads
// Web apps hand out files that the web view would otherwise drop or render invisibly, f.ex. Collabora:
// - "Download as": loads a "Content-Disposition: attachment" response into a hidden iframe
// - "Print": generates a PDF in-page and loads it as blob: URL into a hidden iframe, then calls print() (unsupported in WKWebView)
// These become downloads: "Print" opens the print dialog, everything else QuickLook (which offers print, share and save).
// Everything else keeps WebKit's default behaviour.
private class DownloadHandler: NSObject, WKNavigationDelegate, WKDownloadDelegate, QLPreviewControllerDataSource, UIPrintInteractionControllerDelegate {
	enum DownloadReason: String {
		case attachment
		case inPagePDF = "in-page PDF"
	}

	weak var viewController: ClientWebAppViewController?

	private var downloadsDirectory: URL?
	private var activeDownloads: [WKDownload: URL] = [:]
	private var previewController: QLPreviewController?
	private var previewURL: URL?
	private var printDownloads = Set<WKDownload>()
	private var isPresentingPrintDialog = false
	private var isCleanedUp = false

	init(viewController: ClientWebAppViewController) {
		self.viewController = viewController
	}

	deinit {
		cancelAndCleanUp()
	}

	var isPresentingPreview: Bool {
		return (previewController?.presentingViewController != nil) || isPresentingPrintDialog
	}

	// MARK: Navigation policy
	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		// <a download> links
		if navigationAction.shouldPerformDownload {
			Log.debug("Web app download (link with download attribute), mainFrame=\(navigationAction.targetFrame?.isMainFrame.description ?? "nil")")
			decisionHandler(.download)
		} else {
			decisionHandler(.allow)
		}
	}

	func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
		if let reason = downloadReason(navigationResponse) {
			Log.debug("Web app download (\(reason.rawValue)), mimeType=\(navigationResponse.response.mimeType ?? "nil"), mainFrame=\(navigationResponse.isForMainFrame)")
			decisionHandler(.download)
		} else {
			// WebKit's default without a navigation delegate
			decisionHandler(navigationResponse.canShowMIMEType ? .allow : .cancel)
		}
	}

	/// Reason to turn this response into a download, or nil to keep WebKit's default
	private func downloadReason(_ navigationResponse: WKNavigationResponse) -> DownloadReason? {
		let response = navigationResponse.response

		// Server asks for a download
		if let disposition = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Disposition"),
		   disposition.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("attachment") {
			return .attachment
		}

		// PDF generated in-page and loaded into a frame (Collabora "Print")
		if !navigationResponse.isForMainFrame, response.url?.scheme == "blob", response.mimeType == "application/pdf" {
			return .inPagePDF
		}

		return nil
	}

	func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
		download.delegate = self
	}

	func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
		download.delegate = self

		if downloadReason(navigationResponse) == .inPagePDF {
			printDownloads.insert(download)
		}
	}

	// MARK: Download
	func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
		guard !isCleanedUp else {
			completionHandler(nil) // cancels the download
			return
		}

		if downloadsDirectory == nil {
			downloadsDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("WebAppDownloads", isDirectory: true).appendingPathComponent(UUID().uuidString, isDirectory: true)
		}

		// Own folder per download, so names never collide and the file keeps its name for sharing
		guard let folderURL = downloadsDirectory?.appendingPathComponent(UUID().uuidString, isDirectory: true),
		      (try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)) != nil else {
			completionHandler(nil)
			return
		}

		let fileURL = folderURL.appendingPathComponent(fileName(suggestedFilename: suggestedFilename, response: response))
		activeDownloads[download] = fileURL
		completionHandler(fileURL)
	}

	private func fileName(suggestedFilename: String, response: URLResponse) -> String {
		var name = (suggestedFilename as NSString).lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)

		// In-page generated files (blob:) carry no name: use the document's
		if response.url?.scheme == "blob", let title = viewController?.navigationItem.title, !title.isEmpty {
			name = ((title as NSString).lastPathComponent as NSString).deletingPathExtension
		}

		if name.isEmpty || name.hasPrefix(".") {
			name = "Download" + name
		}

		if (name as NSString).pathExtension.isEmpty, let mimeType = response.mimeType, let fileExtension = UTType(mimeType: mimeType)?.preferredFilenameExtension {
			name = (name as NSString).appendingPathExtension(fileExtension) ?? name
		}

		return name
	}

	func downloadDidFinish(_ download: WKDownload) {
		let isPrint = (printDownloads.remove(download) != nil)
		guard let fileURL = activeDownloads.removeValue(forKey: download), !isCleanedUp else { return }

		if isPrint, presentPrintDialog(for: fileURL) {
			return
		}
		presentPreview(of: fileURL)
	}

	func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
		activeDownloads.removeValue(forKey: download)
		printDownloads.remove(download)

		let nsError = error as NSError
		guard !isCleanedUp, !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) else { return }

		Log.error("Web app download failed: \(error.localizedDescription)")

		guard let presenter = topPresenter() else { return }
		let alert = ThemedAlertController(with: OCLocalizedString("Error", nil), message: error.localizedDescription, okLabel: OCLocalizedString("OK", nil), action: nil)
		presenter.present(alert, animated: true)
	}

	// MARK: Preview
	private func topPresenter() -> UIViewController? {
		guard let viewController, viewController.viewIfLoaded?.window != nil else { return nil }

		var presenter: UIViewController = viewController
		while let presented = presenter.presentedViewController, !presented.isBeingDismissed {
			presenter = presented
		}
		return presenter
	}

	private func presentPreview(of fileURL: URL) {
		previewURL = fileURL

		// Already showing a preview: switch it to the new file
		if let previewController, previewController.presentingViewController != nil {
			previewController.reloadData()
			return
		}

		guard let viewController, let presenter = topPresenter() else { return }

		let previewController = QLPreviewController()
		previewController.dataSource = self
		previewController.modalPresentationStyle = .pageSheet // keeps the web app underneath alive (no viewDidDisappear)
		previewController.overrideUserInterfaceStyle = viewController.overrideUserInterfaceStyle
		self.previewController = previewController

		presenter.present(previewController, animated: true)
	}

	// MARK: Print
	/// Returns false if printing isn't possible, so the caller can fall back to the preview
	private func presentPrintDialog(for fileURL: URL) -> Bool {
		guard !isPresentingPrintDialog, let viewController, topPresenter() === viewController,
		      UIPrintInteractionController.isPrintingAvailable, UIPrintInteractionController.canPrint(fileURL) else {
			return false
		}

		let printInfo = UIPrintInfo.printInfo()
		printInfo.outputType = .general
		printInfo.jobName = fileURL.lastPathComponent

		let printController = UIPrintInteractionController.shared
		printController.printInfo = printInfo
		printController.printingItem = fileURL
		printController.delegate = self

		let completion: UIPrintInteractionController.CompletionHandler = { [weak self] (_, _, error) in
			self?.isPresentingPrintDialog = false
			if let error {
				Log.error("Web app print failed: \(error.localizedDescription)")
			}
		}

		isPresentingPrintDialog = true

		let presented: Bool
		if viewController.traitCollection.userInterfaceIdiom == .pad, let view = viewController.view {
			presented = printController.present(from: CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1), in: view, animated: true, completionHandler: completion)
		} else {
			presented = printController.present(animated: true, completionHandler: completion)
		}

		if !presented {
			isPresentingPrintDialog = false
		}
		return presented
	}

	func printInteractionControllerParentViewController(_ printInteractionController: UIPrintInteractionController) -> UIViewController? {
		return viewController
	}

	// MARK: Preview data source
	func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
		return (previewURL != nil) ? 1 : 0
	}

	func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
		return (previewURL ?? URL(fileURLWithPath: "/")) as NSURL
	}

	// MARK: Clean up
	func cancelAndCleanUp() {
		isCleanedUp = true

		for download in activeDownloads.keys {
			download.cancel(nil)
		}
		activeDownloads.removeAll()
		printDownloads.removeAll()

		if isPresentingPrintDialog {
			UIPrintInteractionController.shared.dismiss(animated: false)
			isPresentingPrintDialog = false
		}

		if let downloadsDirectory {
			try? FileManager.default.removeItem(at: downloadsDirectory)
			self.downloadsDirectory = nil
		}
	}
}
