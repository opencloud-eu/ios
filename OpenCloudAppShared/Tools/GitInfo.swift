//
//  GitInfo.swift
//  OpenCloudAppShared
//
//  Created by Felix Schwarz on 05.05.23.
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
import OpenCloudApp

public class GitInfo: NSObject {
	public var bundle: Bundle

	public lazy var lastCommit: String? = bundle.object(forInfoDictionaryKey: "LastGitCommit") as? String
	public lazy var tags: String? = bundle.object(forInfoDictionaryKey: "GitTags") as? String
	public lazy var branch: String? = bundle.object(forInfoDictionaryKey: "GitBranch") as? String
	public lazy var buildDate: String? = bundle.object(forInfoDictionaryKey: "BuildDate") as? String
	public lazy var isDirty: Bool = (bundle.object(forInfoDictionaryKey: "GitDirty") as? String) == "1"
	public lazy var sdkCommit: String? = { // Only set if the SDK isn't the commit pinned by the app commit
		let commit = bundle.object(forInfoDictionaryKey: "GitSDKCommit") as? String
		return (commit?.isEmpty == false) ? commit : nil
	}()
	public lazy var versionInfo: String = {
		var info = showVerboseVersionInfo ? "\(branch ?? "?")@\(lastCommit ?? "?")" : "\(lastCommit ?? "?")"

		if isDirty {
			info += "-dirty"
		}

		if let sdkCommit {
			info += " · sdk \(sdkCommit) (≠ submodule)"
		}

		return info
	}()

	public lazy var isMainBranch: Bool = (branch == "master") || (branch == "main")
	public lazy var showVerboseVersionInfo: Bool = !isMainBranch || VendorServices.shared.showBetaWarning

	public init(bundle: Bundle) {
		self.bundle = bundle
	}

	public static var app = GitInfo(bundle: .main)

	// f.ex. "OpenCloud 1.2.6 (2) beta · 2026-10-15 · testflight_2026oct15@72f76b09"
	public static var versionSummary: String {
		var summary = "\(VendorServices.shared.appName)\(OCLicenseEMMProvider.isEMMVersion ? "-EMM" : "") \(VendorServices.shared.appVersion) (\(VendorServices.shared.appBuildNumber))"

		if VendorServices.shared.isBetaBuild {
			summary += " beta"
		}

		if let buildDate = app.buildDate {
			summary += " · \(buildDate)"
		}

		return summary + " · \(app.versionInfo)"
	}
}
