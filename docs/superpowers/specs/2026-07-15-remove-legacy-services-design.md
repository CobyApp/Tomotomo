# Legacy Services Removal Design

## Goal

Remove StoreKit in-app purchases and all unreachable Supabase, authentication,
friends, blocking, and direct-message legacy behavior. Keep the app focused on
local Hive storage, AI character chat, custom characters, the notebook
widget, and rewarded-ad point earning.

## Product Scope

### Keep

- Local profiles, characters, chats, points, themes, and saved expressions in Hive.
- AI character chat and expression explanations used by active character chat.
- Custom character creation and X profile import.
- Rewarded AdMob videos as the only way to earn additional points.
- iOS and Android notebook widgets.
- Korean and Japanese locale support, with user-facing Japanese copy preserved.

### Remove

- StoreKit and Google Play in-app purchase flows, product catalogs, receipts,
  purchase repository APIs, tests, and localized purchase copy.
- Supabase migrations, setup instructions, stale architecture descriptions, and
  user-facing Supabase errors.
- Unreachable authentication, friends, blocked-user, public-character, and
  direct-message models, branches, repository methods, localized strings, and UI.
- Direct dependencies with no runtime or tooling use.
- Stale native microphone and speech-recognition permissions when no speech
  plugin or feature remains.

## UI Behavior

The existing points top-up destination remains so current navigation does not
break, but it becomes a rewarded-ad-only point earning screen. Purchase pack
cards, store loading, retry, price, receipt, and purchase success states are
removed. Existing entry points use Japanese point-earning copy rather than
purchase or charge wording.

When points are insufficient, the prompt continues to offer watching an ad and
opening the point earning screen. Daily ad limits and point rewards remain
unchanged.

## Data and Compatibility

Existing Hive boxes and active records remain intact. Obsolete keys such as IAP
transaction IDs and DM unlocks are no longer read or written; no destructive
on-device migration is required. Old values may remain harmlessly in existing
Hive files.

The app keeps its current bundle identifiers, signing team, App Group, and AdMob
native configuration. Removing `in_app_purchase` and regenerating Flutter and
CocoaPods metadata removes the StoreKit plugin from registration.

## Documentation

README and SETTINGS describe the actual local architecture and optional AdMob
environment variables. Supabase-era architecture,
migrations, and superseded implementation plans are removed when they describe
features that no longer exist.

## Verification

- Search for StoreKit/IAP, Supabase, authentication, friends, blocking, and DM
  references that should no longer exist.
- Run dependency resolution and CocoaPods installation.
- Run formatting, `flutter analyze`, and the complete Flutter test suite.
- Build and install profile mode on the wireless iPhone named Coby.
- Confirm launch output no longer initializes `SKPaymentQueue`; AdMob StoreKit
  attribution APIs may remain only if required by the retained ads SDK.
