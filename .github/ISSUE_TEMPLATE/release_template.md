---
name: Release
about: List of checklist to accomplish for the OpenCloud team to finish the release process
title: "[RELEASE]"
labels: Release
assignees: ''

---

Release a new version

Xcode version to work with:

## TASKS:

### Git & Code

* [ ] [DEV] Update SBOM (TODO)
- [ ] [GIT] Create branch `release/[major].[minor].[patch]` (freeze the code)
- [ ] [DEV] Update `APP_SHORT_VERSION` `[major].[minor].[patch]` in [OpenCloud.xcodeproj/project.pbxproj](https://github.com/opencloud-eu/ios/blob/main/OpenCloud.xcodeproj/project.pbxproj)
- [ ] [TRFX] Update translations from transifex.
- [ ] [TRFX] Check for missing translations.
- [ ] [DIS] Update changelog (TODO: ready-release-go)
- [ ] [DEV] Update In-App Release Notes (changelog) in OpenCloud/Release Notes/ReleaseNotes.plist
- [ ] [DEV] Inform Documentation-Team for the upcoming major/minor release with new version tag (notify support team in matrix)
- [ ] [QA] Design Test plan
- [ ] [QA] Regression Test plan
- [ ] [DOC] Update version number on opencloud.eu website (notify marketing team in matrix)
- [ ] [GIT] Merge branch `release/[major].[minor].[patch]` into `main`
- [ ] [GIT] Create tag and sign it `[major].[minor].[patch]`
- [ ] [GIT] Add the new release on [GitHub ios](https://github.com/opencloud-eu/ios/releases)
- [ ] [DEV] Update used Xcode version for the release in [.xcode-version](https://github.com/opencloud-eu/ios/blob/main/.xcode-version)

If it is required to update the iOS-SDK version:

- [ ] [GIT] Create branch library `release/[major].[minor].[patch]`(freeze the code)
- [ ] [DIS] Update README.md (version number, third party, supported versions of iOS, Xcode)
- [ ] [DIS] Update changelog (TODO: ready-release-go)
- [ ] [GIT] Merge branch `release/[major].[minor].[patch]` into `main`
- [ ] [GIT] Create tag and sign it `[major].[minor].[patch]`
- [ ] [GIT] Add the new release on [GitHub ios-sdk](https://github.com/opencloud-eu/ios-sdk/releases)

If it is required to update third party:

- [ ] [DIS] Update THIRD_PARTY.txt

## App Store

- [ ] [DIS] App Store Connect: Create a new version following the `[major].[minor].[patch]`
- [ ] [DIS] App Store Connect: Trigger Fastlane screenshots generation and upload
- [ ] [DIS] Upload the binary to the App Store
- [ ] [DIS] App Store Connect: Trigger release (manually)
- [ ] [DIS] App Store Connect: Decide reset of iOS summary rating (Default: keep)
- [ ] [DIS] App Store Connect: Update description if necessary (coordinated with #marketing)
- [ ] [DIS] App Store Connect: Update changelogs
- [ ] [DIS] App Store Connect: Submit for review

## BUGS & IMPROVEMENTS:
