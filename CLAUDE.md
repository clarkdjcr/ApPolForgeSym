# Campaign Manager 2026 — CLAUDE.md

Project context and instructions for Claude Code sessions.

---

## Project Overview

**App name:** Campaign Manager 2026
**Bundle ID:** `clarkdjcr.ApPolForgeSym`
**Version:** 2.0 (build 3)
**Platform:** iOS 26.2+, iPadOS 26.2+, macOS 26.2+, visionOS 26.2+
**Language:** Swift 5.0 / SwiftUI
**Firebase project:** `peach-bfdf0` (us-central1)

Two repos:
- **iOS app:** `github.com/clarkdjcr/ApPolForgeSym` (this repo)
- **Firebase backend:** `github.com/clarkdjcr/PolForge`

---

## Repo Structure

```
ApPolForgeSym/                  ← Xcode target root (PBXFileSystemSynchronizedRootGroup)
  ApPolForgeSymApp.swift        ← App entry point; FirebaseApp.configure() guarded by plist check
  ContentView.swift             ← Root tab view (Map, Actions, Strategy, Events)
  AppSettings.swift             ← User preferences, AI difficulty, haptics
  Models/
    LivePollingModels.swift     ← PollAverage, LivePoll, CongressionalRace, etc.
    CongressionalModels.swift   ← Senate/House race models
    IssueNewsModels.swift       ← NewsArticle, PollIssueCorrelation, PolicyIssueCategory
    EmailCampaignModels.swift   ← CampaignEmail, EmailTemplate, UserCandidate
  Services/
    FirestoreService.swift      ← @MainActor singleton; reads polls, news, correlations from Firestore
    BiweeklyRefreshManager.swift← BGAppRefreshTask registration + scheduling
    EmailComposerService.swift  ← HTML/plain-text campaign email builder
    IssueCorrelationEngine.swift← Correlates polling swings to issue categories
    NewsAggregatorService.swift ← Aggregates and classifies news articles
    PollScraperService.swift    ← Client-side poll fetch helper
  Views/                        ← Feature views
  GoogleService-Info.plist      ← Firebase config (bundle: clarkdjcr.ApPolForgeSym, project: peach-bfdf0)
ApPolForgeSymTests/             ← Unit tests
ApPolForgeSymUITests/           ← UI tests
  ApPolForgeSymUITests.swift
  ApPolForgeSymUITestsLaunchTests.swift
Campain_Manager.xcworkspace     ← Open this, NOT the .xcodeproj
```

---

## Common Commands

### Build
```bash
xcodebuild \
  -workspace Campain_Manager.xcworkspace \
  -scheme ApPolForgeSym \
  -destination "platform=iOS Simulator,id=B88B5030-2A3B-4A37-97DA-8368FC10BBA1" \
  -configuration Debug \
  build 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

### Test (iPhone 17 simulator, OS 26.2)
```bash
xcodebuild \
  -workspace Campain_Manager.xcworkspace \
  -scheme ApPolForgeSym \
  -destination "platform=iOS Simulator,id=B88B5030-2A3B-4A37-97DA-8368FC10BBA1" \
  -configuration Debug \
  test 2>&1 | grep -E "Test Case|error:|passed|failed|BUILD"
```

### List available simulators
```bash
xcodebuild -workspace Campain_Manager.xcworkspace -scheme ApPolForgeSym -showdestinations 2>&1 | grep "iOS Simulator"
```

### Deploy Firebase backend (from PolForge/ root)
```bash
firebase deploy --only functions,firestore
```

### Firebase logs
```bash
firebase functions:log --project peach-bfdf0
```

---

## Firebase Architecture

- **Firestore rules:** Read-only for all clients. All writes via Admin SDK in Cloud Functions.
- **Cloud Functions (us-central1):**
  - `pollScraper` — scheduled every 14 days, scrapes FiveThirtyEight CSV → Firestore
  - `triggerPollScraper` — callable trigger for manual refresh
  - `newsProcessor` — ingests and classifies news events
- **Firestore schema:**
  - `polls/{raceId}/metadata/summary` — PollAverage
  - `polls/{raceId}/pollData/{pollId}` — LivePoll
  - `congressional/{state}/{chamber}/{cycle}/` — CongressionalRace
  - `issues/{raceId}/correlations/{issueCategory}` — PollIssueCorrelation
  - `newsEvents/{articleId}` — NewsArticle
  - `refreshLog/{refreshId}` — audit log

**iOS client:** `FirestoreService.shared` — call `performFullRefresh(raceIds:)` on app launch or after biweekly background refresh.

---

## Known Decisions & Fixes

- **Firebase init guard** (`ApPolForgeSymApp.swift`): `FirebaseApp.configure()` is wrapped in a `Bundle.main.path(forResource:ofType:)` check so the app doesn't crash in test environments without the plist.
- **`EmailComposerService`**: `EmailOptions.init()` is marked `nonisolated` to resolve Swift 6 main-actor isolation error when used as a default parameter value.
- **`testLaunch()` fix**: Removed `runsForEachTargetApplicationUIConfiguration = true` (caused 4 parallel simulator clones to race on app install). Added `app.wait(for: .runningForeground, timeout: 15)` before screenshot.
- **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`** is set project-wide in build settings.

---

## App Store Submission

### Current status
- [ ] Archive built and validated
- [ ] Uploaded to App Store Connect
- [ ] Screenshots uploaded
- [ ] Metadata complete
- [ ] Submitted for review

### Step 1 — Bump version/build if needed
In `project.pbxproj` (or Xcode target settings):
- `MARKETING_VERSION` = user-facing version (e.g. `1.0`)
- `CURRENT_PROJECT_VERSION` = build number (increment each upload, e.g. `2`)

### Step 2 — Archive
```bash
xcodebuild \
  -workspace Campain_Manager.xcworkspace \
  -scheme ApPolForgeSym \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath ~/Desktop/CampaignManager.xcarchive \
  archive 2>&1 | grep -E "error:|ARCHIVE SUCCEEDED|ARCHIVE FAILED"
```

### Step 3 — Export IPA
```bash
xcodebuild \
  -exportArchive \
  -archivePath ~/Desktop/CampaignManager.xcarchive \
  -exportPath ~/Desktop/CampaignManager-Export \
  -exportOptionsPlist ExportOptions.plist 2>&1
```

`ExportOptions.plist` (create at project root if missing):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>teamID</key>
  <string>965RA266P3</string>
  <key>uploadSymbols</key>
  <true/>
  <key>compileBitcode</key>
  <false/>
</dict>
</plist>
```

### Step 4 — Upload to App Store Connect
```bash
xcrun altool --upload-app \
  -f ~/Desktop/CampaignManager-Export/ApPolForgeSym.ipa \
  -t ios \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```
Or use Xcode → Product → Archive → Distribute App → App Store Connect.

### Step 5 — App Store Connect metadata

| Field | Value |
|---|---|
| App name | Campaign Manager 2026 |
| Bundle ID | `clarkdjcr.ApPolForgeSym` |
| SKU | `CampaignManager2026` |
| Primary category | Games → Strategy |
| Secondary category | Games → Simulation |
| Age rating | 12+ |
| Privacy policy URL | *(host Privacy_Policy.md publicly)* |
| Support URL | *(GitHub or support page)* |

**Keywords (100 chars):**
```
politics,strategy,election,campaign,president,electoral,simulation,management,tactics,government
```

**Subtitle (30 chars):**
```
Master the Electoral College
```

### Step 6 — Screenshots required
| Device | Size |
|---|---|
| iPhone 6.7" (Pro Max) | 1290 × 2796 |
| iPhone 6.5" | 1242 × 2688 |
| iPad Pro 12.9" | 2048 × 2732 |

Minimum 3 per device, maximum 10. Suggested screens:
1. Electoral map overview
2. Campaign actions / multi-state targeting
3. Strategic dashboard with analytics
4. Event notification
5. Shadow budget / Nixon Disease screen

### Step 7 — Privacy manifest
Add `PrivacyInfo.xcprivacy` to the target if not present. Required for any app using:
- `UserDefaults` → declare `NSPrivacyAccessedAPICategoryUserDefaults`
- No user data collected, no tracking — declare `NSPrivacyCollectedDataTypes: []`

### Step 8 — Review notes for Apple
```
This is a single-player political strategy game simulating a U.S. presidential campaign.
No account or login required. No user data collected.
Optional AI features (OpenAI/Anthropic) require a user-supplied API key stored in Keychain.
Firebase Firestore is used read-only to display live polling data (no authentication required).
To test: tap "Start Campaign", select a party, and play through the 20-week campaign.
```

---

## Development Team

- **Team ID:** `965RA266P3`
- **Apple ID / developer account:** Donald Clark
- **Code signing:** Automatic

---

## Dependencies

| Package | Version | Source |
|---|---|---|
| `firebase-ios-sdk` | 11.15.0 (≥11.0.0) | SPM — github.com/firebase/firebase-ios-sdk |
| FirebaseCore | via above | Linked to app target |
| FirebaseFirestore | via above | Linked to app target |

No CocoaPods. No Carthage.

---

## Node Functions Dependencies (PolForge repo)

| Package | Version |
|---|---|
| `firebase-admin` | ^12.5.0 |
| `firebase-functions` | ^6.0.1 |
| `axios` | ^1.7.7 |
| `cheerio` | ^1.0.0 |
| `csv-parse` | ^5.5.6 |

**Upcoming:** Node 20 is deprecated April 30, 2026. Upgrade `engines.node` to `"22"` in `functions/package.json` before then.
