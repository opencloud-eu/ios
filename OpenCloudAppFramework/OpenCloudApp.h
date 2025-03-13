//
//  OpenCloudApp.h
//  OpenCloudApp
//
//  Created by Felix Schwarz on 21.05.19.
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

#import <UIKit/UIKit.h>
#import "DisplaySettings.h"

//! Project version number for OpenCloudApp.
FOUNDATION_EXPORT double OpenCloudAppVersionNumber;

//! Project version string for OpenCloudApp.
FOUNDATION_EXPORT const unsigned char OpenCloudAppVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <OpenCloudApp/PublicHeader.h>
#import <OpenCloudApp/DisplaySettings.h>
#import <OpenCloudApp/NSData+Encoding.h>
#import <OpenCloudApp/OCCore+BundleImport.h>
#import <OpenCloudApp/OCBookmark+AppExtensions.h>
#import <OpenCloudApp/OCSearchSegment.h>
#import <OpenCloudApp/OCQueryCondition+SearchSegmenter.h>
#import <OpenCloudApp/NSObject+AnnotatedProperties.h>
#import <OpenCloudApp/NSDate+RFC3339.h>
#import <OpenCloudApp/NSDate+ComputedTimes.h>

#import <OpenCloudApp/UIViewController+HostBundleID.h>

#import <OpenCloudApp/OCBookmark+FPServices.h>
#import <OpenCloudApp/OCVault+FPServices.h>
#import <OpenCloudApp/OCCore+FPServices.h>
#import <OpenCloudApp/OCFileProviderService.h>
#import <OpenCloudApp/OCFileProviderServiceSession.h>
#import <OpenCloudApp/OCFileProviderServiceStandby.h>
#import <OpenCloudApp/OCFileProviderSettings.h>

#import <OpenCloudApp/OCLicenseTypes.h>
#import <OpenCloudApp/OCLicenseManager.h>
#import <OpenCloudApp/OCLicenseObserver.h>

#import <OpenCloudApp/OCLicenseFeature.h>
#import <OpenCloudApp/OCLicenseProduct.h>

#import <OpenCloudApp/OCLicenseProvider.h>
#import <OpenCloudApp/OCLicenseEntitlement.h>
#import <OpenCloudApp/OCLicenseOffer.h>
#import <OpenCloudApp/OCLicenseDuration.h>
#import <OpenCloudApp/OCLicenseTransaction.h>

#import <OpenCloudApp/OCLicenseAppStoreProvider.h>
#import <OpenCloudApp/OCLicenseAppStoreItem.h>
#import <OpenCloudApp/OCLicenseAppStoreReceipt.h>
#import <OpenCloudApp/OCLicenseAppStoreReceiptInAppPurchase.h>

#import <OpenCloudApp/OCLicenseEnterpriseProvider.h>

#import <OpenCloudApp/OCLicenseEMMProvider.h>

#import <OpenCloudApp/OCLicenseQAProvider.h>

#import <OpenCloudApp/OCLicenseEnvironment.h>
#import <OpenCloudApp/OCCore+LicenseEnvironment.h>

#import <OpenCloudApp/NotificationManager.h>
#import <OpenCloudApp/NotificationMessagePresenter.h>
#import <OpenCloudApp/NotificationAuthErrorForwarder.h>

#import <OpenCloudApp/Branding.h>
#import <OpenCloudApp/OCThemeValues.h>
#import <OpenCloudApp/AppLockSettings.h>

#import <OpenCloudApp/OCViewHost.h>
#import <OpenCloudApp/OCImage+ViewProvider.h>
#import <OpenCloudApp/OCResourceTextPlaceholder+ViewProvider.h>
#import <OpenCloudApp/OCCircularContentView.h>
#import <OpenCloudApp/OCCircularImageView.h>
#import <OpenCloudApp/UIImage+ViewProvider.h>

#import <OpenCloudApp/VFSManager.h>

#import <OpenCloudApp/OCSavedSearch.h>
#import <OpenCloudApp/OCVault+SavedSearches.h>

#import <OpenCloudApp/OCSidebarItem.h>
#import <OpenCloudApp/OCVault+SidebarItems.h>

#import <OpenCloudApp/ConfidentialManager.h>

#import <OpenCloudApp/NSURL+OCVaultTools.h>
