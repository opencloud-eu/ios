//
//  OCLicenseFreeProvider.m
//  OpenCloudAppShared
//
//  Created by Markus Goetz on 26.3.2025.
//  Copyright © 2025 OpenCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2025, OpenCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://opencloud.eu/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import <OpenCloudSDK/OpenCloudSDK.h>
#import "OCLicenseFreeProvider.h"
#import "OCLicenseEntitlement.h"
#import "OCLicenseProduct.h"
#import "OCLicenseFeature.h"
#import "OCLicenseManager.h"


@implementation OCLicenseFreeProvider
{
}

#pragma mark - Init
- (instancetype)initWithUnlockedProductIdentifiers:(NSArray<OCLicenseProductIdentifier> *)unlockedProductIdentifiers
{
	if ((self = [super initWithIdentifier:OCLicenseProviderIdentifierFree]) != nil)
	{
		_unlockedProductIdentifiers = unlockedProductIdentifiers;

		self.localizedName = @"free";
	}

	return (self);
}

#pragma mark - Providing and updating entitlements
- (void)startProvidingWithCompletionHandler:(OCLicenseProviderCompletionHandler)completionHandler
{
	[self updateEntitlements];

	completionHandler(self, nil);
}

- (void)updateEntitlements
{
	NSMutableArray<OCLicenseEntitlement *> *entitlements = [NSMutableArray new];

	for (OCLicenseProductIdentifier productIdentifier in self.unlockedProductIdentifiers)
	{
		OCLicenseEntitlement *entitlement;

		entitlement = [OCLicenseEntitlement entitlementWithIdentifier:nil forProduct:productIdentifier type:OCLicenseTypePurchase valid:YES expiryDate:nil applicability:nil]; // Valid entitlement for all environments

		[entitlements addObject:entitlement];
	}

	self.entitlements = (entitlements.count > 0) ? entitlements : nil;
}

#pragma mark - Unlock message

- (NSString *)inAppPurchaseMessageForFeature:(OCLicenseFeatureIdentifier)featureIdentifier
{
	return @""; // should not be used nowadays
}

#pragma mark -


@end

OCLicenseProviderIdentifier OCLicenseProviderIdentifierFree = @"free";
