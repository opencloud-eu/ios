//
//  DisplaySettings.h
//  OpenCloud
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

#import <Foundation/Foundation.h>
#import <OpenCloudSDK/OpenCloudSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface DisplaySettings : NSObject <OCClassSettingsSupport, OCQueryFilter>

#pragma mark - Singleton
@property(class,strong,nonatomic,readonly) DisplaySettings *sharedDisplaySettings;

#pragma mark - Show hidden files
@property(assign,nonatomic) BOOL showHiddenFiles;

#pragma mark - Folders first
@property(assign,nonatomic) BOOL sortFoldersFirst;

#pragma mark - Drag files
@property(assign,nonatomic) BOOL preventDraggingFiles;

#pragma mark - OIDC Claim
@property(assign,nonatomic) NSString *oidcCustomClaim;

#pragma mark - Query condition
@property(nonatomic,readonly,nullable) OCQueryCondition *queryConditionForDisplaySettings;

#pragma mark - Query updating
- (void)updateQueryWithDisplaySettings:(OCQuery *)query;

@end

extern NSString *DisplaySettingsShowHiddenFilesPrefsKey;			//!< The UserDefaults Key containing the BOOL value for .showHiddenFiles
extern NSString *DisplaySettingsSortFoldersFirstPrefsKey;			//!< The UserDefaults Key containing the BOOL value for .sortFoldersFirst
extern NSString *DisplaySettingsPreventDraggingFilesPrefsKey;			//!< The UserDefaults Key containing the BOOL value for .preventDraggingFiles
extern NSString *DisplaySettingsOidcCustomClaimPrefsKey;			//!< The UserDefaults Key containing the BOOL value for .oidcCustomClaim

extern OCIPCNotificationName OCIPCNotificationNameDisplaySettingsChanged; 	//!< Posted when display settings changed (internal use only)
extern NSNotificationName DisplaySettingsChanged;				//!< Posted when display settings changed (for use by app + File Provider)

extern OCClassSettingsIdentifier OCClassSettingsIdentifierDisplay; 		//!< The class settings identifier for the Display Settings
extern OCClassSettingsKey OCClassSettingsKeyDisplayShowHiddenFiles;		//!< The class settings key for Show Hidden Files
extern OCClassSettingsKey OCClassSettingsKeyDisplaySortFoldersFirst;		//!< The class settings key for sorting folders first
extern OCClassSettingsKey OCClassSettingsKeyDisplayPreventDraggingFiles;	//!< The class settings key if Drag Files is enabled
extern OCClassSettingsKey OCClassSettingsKeyCustomOidcClaim;	//!< The class settings key for custom OIDC claim

NS_ASSUME_NONNULL_END
