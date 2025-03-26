//
//  OCLicenseFreeProvider.h
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

#import "OCLicenseProvider.h"

NS_ASSUME_NONNULL_BEGIN


@interface OCLicenseFreeProvider : OCLicenseProvider

@property(strong,readonly) NSArray<OCLicenseProductIdentifier> *unlockedProductIdentifiers;

- (instancetype)initWithUnlockedProductIdentifiers:(NSArray<OCLicenseProductIdentifier> *)unlockedProductIdentifiers;

- (void)updateEntitlements;

@end

extern OCLicenseProviderIdentifier OCLicenseProviderIdentifierFree;

NS_ASSUME_NONNULL_END
