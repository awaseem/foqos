# Model extraction audit

Reviewed on 2026-09-14. Baseline: `6883cd0` (before widget/model refactor `560c128`). Widget polish: `19cad89`.

No behavior regression was found in the model extraction. Every moved member matches its original signature and body exactly. Stored fields, defaults, unique attributes, relationship declarations and initializer assignments are unchanged. Comments are also retained.

The sole initializer code substitution is `NFCBlockingStrategy.id` → `"NFCBlockingStrategy"`. The original identifier has that value; no assignments to that static property were found in app code. The default-strategy regression test checks it against the app strategy identifier.

## Line-by-line verification

Run `python3 scripts/validate-model-extraction.py`. It matches each complete extracted member literally against the original Git source (including its internal whitespace, comments and statements), removes those matched members, then compares every remaining code line. It also checks imports and comments separately. Only blank lines, file wrapper placement and the explicitly verified strategy substitution are allowed. The script exits with a failure if any check fails. It is an audit for this specific extraction, not a general Swift parser.

Validated 44 exact member moves against 6883cd0.
All stored declarations, attributes, relationships and initializer code match;
the profile default strategy substitution has the same verified value.

| Member | Before | After | Result |
| --- | --- | --- | --- |
| `activeScheduleTimerActivity` | `BlockedProfiles.swift:58` | `BlockedProfiles+App.swift:9` | Exact match |
| `scheduleIsOutOfSync` | `BlockedProfiles.swift:62` | `BlockedProfiles+App.swift:13` | Exact match |
| `allowsTimedBreaks` | `BlockedProfiles.swift:67` | `BlockedProfiles+App.swift:18` | Exact match |
| `shouldAskForStartSettings` | `BlockedProfiles.swift:72` | `BlockedProfiles+App.swift:23` | Exact match |
| `canUnblock` | `BlockedProfiles.swift:83` | `BlockedProfiles+App.swift:34` | Exact match |
| `hasPhysicalUnblockItem` | `BlockedProfiles.swift:96` | `BlockedProfiles+App.swift:47` | Exact match |
| `showStopButton` | `BlockedProfiles.swift:163` | `BlockedProfiles+App.swift:52` | Exact match |
| `fetchProfiles` | `BlockedProfiles.swift:176` | `BlockedProfiles+App.swift:65` | Exact match |
| `findProfile` | `BlockedProfiles.swift:187` | `BlockedProfiles+App.swift:76` | Exact match |
| `fetchMostRecentlyUpdatedProfile` | `BlockedProfiles.swift:196` | `BlockedProfiles+App.swift:85` | Exact match |
| `updateProfile` | `BlockedProfiles.swift:205` | `BlockedProfiles+App.swift:94` | Exact match |
| `deleteProfile` | `BlockedProfiles.swift:353` | `BlockedProfiles+App.swift:242` | Exact match |
| `getProfileDeepLink` | `BlockedProfiles.swift:380` | `BlockedProfiles+App.swift:269` | Exact match |
| `getSnapshot` | `BlockedProfiles.swift:384` | `BlockedProfiles+App.swift:273` | Exact match |
| `updateSnapshot` | `BlockedProfiles.swift:418` | `BlockedProfiles+App.swift:307` | Exact match |
| `deleteSnapshot` | `BlockedProfiles.swift:423` | `BlockedProfiles+App.swift:312` | Exact match |
| `reorderProfiles` | `BlockedProfiles.swift:427` | `BlockedProfiles+App.swift:316` | Exact match |
| `getNextOrder` | `BlockedProfiles.swift:437` | `BlockedProfiles+App.swift:326` | Exact match |
| `createProfile` | `BlockedProfiles.swift:447` | `BlockedProfiles+App.swift:336` | Exact match |
| `cloneProfile` | `BlockedProfiles.swift:513` | `BlockedProfiles+App.swift:402` | Exact match |
| `addDomain` | `BlockedProfiles.swift:550` | `BlockedProfiles+App.swift:439` | Exact match |
| `removeDomain` | `BlockedProfiles.swift:563` | `BlockedProfiles+App.swift:452` | Exact match |
| `isActive` | `BlockedProfileSessions.swift:23` | `BlockedProfileSession+App.swift:6` | Exact match |
| `isBreakAvailable` | `BlockedProfileSessions.swift:27` | `BlockedProfileSession+App.swift:10` | Exact match |
| `isBreakActive` | `BlockedProfileSessions.swift:41` | `BlockedProfileSession+App.swift:24` | Exact match |
| `isPauseActive` | `BlockedProfileSessions.swift:48` | `BlockedProfileSession+App.swift:31` | Exact match |
| `duration` | `BlockedProfileSessions.swift:52` | `BlockedProfileSession+App.swift:35` | Exact match |
| `totalBreakAllowanceInSeconds` | `BlockedProfileSessions.swift:57` | `BlockedProfileSession+App.swift:40` | Exact match |
| `totalBreakDuration` | `BlockedProfileSessions.swift:70` | `BlockedProfileSession+App.swift:53` | Exact match |
| `activeBreakElapsedTime` | `BlockedProfileSessions.swift:104` | `BlockedProfileSession+App.swift:72` | Exact match |
| `usedBreakDurationIncludingActiveBreak` | `BlockedProfileSessions.swift:112` | `BlockedProfileSession+App.swift:80` | Exact match |
| `remainingBreakAllowance` | `BlockedProfileSessions.swift:123` | `BlockedProfileSession+App.swift:91` | Exact match |
| `startBreak` | `BlockedProfileSessions.swift:127` | `BlockedProfileSession+App.swift:95` | Exact match |
| `endBreak` | `BlockedProfileSessions.swift:140` | `BlockedProfileSession+App.swift:108` | Exact match |
| `completedSingleBreakDuration` | `BlockedProfileSessions.swift:157` | `BlockedProfileSession+App.swift:125` | Exact match |
| `startPause` | `BlockedProfileSessions.swift:173` | `BlockedProfileSession+App.swift:141` | Exact match |
| `endPause` | `BlockedProfileSessions.swift:180` | `BlockedProfileSession+App.swift:148` | Exact match |
| `endSession` | `BlockedProfileSessions.swift:187` | `BlockedProfileSession+App.swift:155` | Exact match |
| `toSnapshot` | `BlockedProfileSessions.swift:204` | `BlockedProfileSession+App.swift:172` | Exact match |
| `mostRecentActiveSession` | `BlockedProfileSessions.swift:220` | `BlockedProfileSession+App.swift:188` | Exact match |
| `createSession` | `BlockedProfileSessions.swift:232` | `BlockedProfileSession+App.swift:200` | Exact match |
| `upsertSessionFromSnapshot` | `BlockedProfileSessions.swift:259` | `BlockedProfileSession+App.swift:227` | Exact match |
| `findSession` | `BlockedProfileSessions.swift:308` | `BlockedProfileSession+App.swift:276` | Exact match |
| `recentInactiveSessions` | `BlockedProfileSessions.swift:318` | `BlockedProfileSession+App.swift:286` | Exact match |

## Store and target validation

- `FoqosModelContainer.make()` calls the same `ModelContainer(for: BlockedProfileSession.self, BlockedProfiles.self)` previously used by the app. No URL, configuration, migration plan or model type changed.
- App and widget App Group entitlements are unchanged. Both use `group.dev.ambitionsoftware.foqos`.
- The widget target includes the two stored-model files and container factory. The two `+App` extensions remain app-only. The app's synchronized source group includes both extension files automatically.
- `Shared.swift`, `PhysicalUnblockItem.swift`, `Schedule.swift`, the legacy physical-code backfill and Device Monitor source are unchanged from the baseline. Device Activity still uses its existing snapshots.
- A real SQLite fixture was generated by the original models in the original `foqos` module. The current models read every profile setting, legacy NFC/QR value, completed-session field and both relationship directions, then update and reopen the store in a new container. The persistent model version hashes are unchanged after the write: no schema migration occurred.

## Regression coverage and results

32 new tests; 83 total app unit tests passed on iPhone 17 Pro, iOS Simulator 26.4.

| Suite | New tests | Coverage |
| --- | ---: | --- |
| BlockedProfilesRegressionTests | 17 | Defaults, persisted fields, snapshots, sorting, lookup, creation, every update parameter, explicit nil/omitted data, timer transitions, Mac restrictions, cloning, domains, deletion, physical codes, stop-button boundary, deep links and missing schedule registration |
| BlockedProfileSessionRegressionTests | 12 | Initialization and relationships, lifecycle callbacks, SharedData side effects, break/pause transitions and allowance boundaries, historical totals, duration, snapshot insert/update/missing-profile handling, query filtering/sorting/limits |
| ModelObservationTests | 2 | Computed-property observation and changes through the session's profile relationship |
| ModelStoreCompatibilityTests | 1 | Pre-refactor SQLite read/update/reopen and unchanged schema hashes |

The 29 profile/session tests also passed unchanged against an isolated archive of `6883cd0`, alongside all 51 existing tests. The two observation tests separately passed against that baseline. The fixture writer ran there as an additional test. Current full-suite result: `test_sim_2026-09-14T23-05-28-012Z_pid43932_fe93103d.xcresult` (83 passed, zero failures/skips). Baseline full-suite result: `test_sim_2026-09-14T23-01-55-673Z_pid43932_2ba17082.xcresult` (81 including fixture writer). Baseline observation result: `test_sim_2026-09-14T23-05-56-690Z_pid43932_d9e985f7.xcresult` (2 passed).

Tests use isolated in-memory containers or temporary copies of the synthetic fixture. The regression base preserves/restores the snapshot and temporary-access UserDefaults keys touched by the tested APIs. Run this suite serially because these existing APIs share an App Group defaults store:

```sh
xcodebuild -project foqos.xcodeproj -scheme foqos   -destination 'platform=iOS Simulator,name=iPhone 17 Pro'   test -only-testing:foqosTests -parallel-testing-enabled NO
```

## Existing behavior retained

These behaviors predate the extraction and were confirmed against the old implementation:

- `updateProfile` clears reminder time/message when those arguments are omitted. `strategyData` and physical items instead use double optionals to distinguish omission from explicit clearing.
- `cloneProfile` resets `disableBackgroundStops` to its initializer default and does not publish a snapshot. It copies the other settings, creates a new identity/order and excludes session history.
- `addDomain` is a no-op when `domains` is nil. An empty array permits the first domain.
- `deleteProfile` deletes related sessions and snapshot state, but intentionally leaves the final context save to its caller.
- Snapshot insertion waits for a caller/autosave; an existing snapshot update saves immediately. The tests disable autosave to verify that distinction.

These are documented rather than changed in this validation task.

## Fixture provenance

`foqosTests/Fixtures/pre-refactor-models.store` contains one synthetic profile and two synthetic sessions, including deprecated fields, custom settings, schedule, physical code, completed break/pause history and an active session. No user database was copied.

Fixture SHA-256: `60ef9a28e5090b628b09e92bef1af1766080eb894c9d16fcc969970ac6afdf41`. Size: 102400 bytes.

To reproduce: archive `6883cd0` to a temporary directory; copy the current `ModelRegressionTestCase.swift` and the adjacent `LegacyFixtureWriterTests.swift` into that archive's `foqosTests` folder; run only `foqosTests/LegacyFixtureWriterTests` on Simulator. Copy the SQLite store printed as `LEGACY_STORE_PATH` using SQLite's backup API (so WAL contents are included) to the fixture path. Keep the app module name `foqos`. The writer belongs outside the normal test target and must run against the baseline, never the refactored models.

## Limits

Simulator tests exercise model logic, SwiftData persistence, observation, snapshots and lifecycle dispatch. They do not validate physical NFC/QR scanning, real Screen Time enforcement, or successful Device Activity schedule registration on a provisioned device. The schedule test covers absent/inactive registration; the scheduling delegation itself is an exact source match. These hardware/system integration behaviors were not modified.
