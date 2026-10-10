# Family outings prototype

Settings → Family time is an opt-in iPhone prototype. Existing profiles, schedules,
widgets, physical unlocks and Mac sync continue to use the existing session engine.
No dependency or server has been added.

## Try it

1. Create a **Manual** profile named Family. Select distracting apps; keep calls,
   camera, navigation and other essentials available. Grant Screen Time access.
2. In Settings → Family time, select that profile. Save the current place, choose
   a 100–1000 m radius, and block either outside it (leaving home) or inside it
   (a park or venue). Enable automation and allow **Always** location access.
3. Optionally enable walking/running/cycling starts and grant Motion & Fitness
   access. These are additional start triggers, not conditions required by the
   geofence. Motion becoming stationary never stops blocking.
4. Use Start/Stop family time to check the selected profile before a real outing.
   Stops only affect the session started by family controls, including after a
   restart. They respect the profile's “disable background stops” setting.
5. Allow notifications for reminders. Received reminder text also appears in the
   local log, including when the app is foregrounded.

Disable automation before changing the profile or place. Disabling automation
stops sensors but leaves an existing block intact. Manually stopping while outside
will not immediately re-arm until another boundary/motion event occurs.

## Partner setup (developer configuration required)

The owner invites a trusted partner using Apple's private CloudKit sharing UI.
The partner installs the same build, opens Family time, pastes the private iCloud
invitation, and chooses Join as partner. Invite just one partner, with read/write
permission. There is no anonymous/public sharing and no new account system.

Before this works on devices, the app's signing team must register/provision
`iCloud.dev.ambitionsoftware.foqos` and enable CloudKit for the app identifier.
For another development team, change that identifier in `FamilyPartnerStore` and
the app entitlements, alongside the usual app-group/Screen Time signing setup.
Create the `FamilyOuting` record type in the development environment by exercising
Invite. Its fields are `audit` (String) and `command` (Bytes). Deploy the schema
before a production/TestFlight build; both phones must use the same environment.
This PR does not create Apple developer resources or deploy a CloudKit schema.

The partner can request start/stop and send a custom reminder (200 characters).
The owner accepts only commands no more than five minutes old, with at most one
minute of future clock skew. Requests are processed once per stored command ID;
a newer request replaces a pending one. Failed/expired commands are logged rather
than silently retried. CloudKit conflicts and connectivity failures are displayed;
refresh and resend if needed.

**Both apps must be open to exchange requests/status.** Each active app refreshes
every 20 seconds; there is also a manual Refresh button. This prototype deliberately
has no APNs/subscription delivery. It is not sufficient for reliable reminders or
control of a locked/backgrounded phone. Background push delivery, reconciliation
and real-device reliability are a separate step before relying on remote control.

The shared status contains current session/break/pause state and the latest 30
local events. The owner retains the latest 100 events. Coordinates, app tokens and
full session history are not uploaded. Sharing the text log is optional. Only
session state changes observed by the main app are logged; it is not an exhaustive
history of extension events, phone pickups or app usage. A trusted read/write
participant can edit shared fields, and the owner can edit local data: this is
cooperative accountability, not a tamper-proof audit or parental-control lock.

Manage invitation can revoke a partner's access using Apple's sharing UI.
Disconnect only forgets the connection on that phone; revoke access first if it
should end. Cloud data remains until the owner removes the share/records in iCloud.

## Platform investigation

- [Core Location geofencing](https://developer.apple.com/documentation/corelocation/monitoring-the-user-s-proximity-to-geographic-regions)
  supports boundary callbacks without continuous GPS. This prototype uses one
  region. Boundaries are approximate and events may be delayed. Always permission,
  Location Services and background availability matter; test force quit, reboot,
  denied permission and disabled Background App Refresh on a physical iPhone.
- [Core Motion activity updates](https://developer.apple.com/documentation/coremotion/cmmotionactivitymanager/startactivityupdates(to:withhandler:))
  distinguish walking/running/cycling/vehicle/stationary states. Updates do not
  continuously wake a suspended app. Motion therefore supplements geofencing;
  it cannot reliably detect that the family is together or that you picked up
  the phone. Low-confidence updates are ignored.
- Foqos already exposes Start Profile to Shortcuts. Arrival/departure and Focus
  automations are a useful way to trial this routine with the existing release.
  Screen Time's existing DeviceActivity monitor controls scheduled blocks; using
  usage thresholds for future partner alerts would require extension integration
  and a separate privacy/accuracy review.
- [CloudKit sharing](https://developer.apple.com/documentation/cloudkit/shared-records)
  handles cross-account private access; same-account ubiquitous key/value sync
  cannot serve a partner on a different Apple ID.

## Validation and device checklist

Validated with Xcode 26.6: all **119** `foqosTests` passed again on iPhone Air /
iOS 26.5 after hands-on testing. Unsigned and Xcode ad-hoc signed simulator builds
passed. A separate local copy with a development team's own bundle/app-group/
CloudKit identifiers also passed an automatically provisioned, signed iPhone build;
those team-specific changes are not part of this PR. No physical iPhone was connected.

Simulator UI checks covered creating/selecting a Manual profile, saving a synthetic
place, enabling automation, granting Always location, and restoring the profile,
place and enabled setting after restart. Start correctly refused missing Screen
Time access; motion reported unavailable hardware. Signed Invite displayed the
missing-iCloud-account error. No invitation was sent. Testing found and fixed an
unwanted Motion permission prompt before opt-in; launch after resetting that
permission no longer prompted. Automation was switched off after testing.

CloudKit UI testing requires a signed build: an unsigned simulator cannot exercise
the CloudKit container. Real shields, motion updates and cross-account sharing
remain unverified. `swift-format lint` completed with five existing naming warnings
and none in new files. Plists and `git diff --check` passed. The project paths were
corrected from `foqos/` to `Foqos/` for this case-sensitive volume. Sparkle's existing
download needed a checksum-verified local cache fill.

Unit coverage includes region input bounds, command expiry/length/round-trip,
family session ownership and restart, manual-strategy/Screen Time checks, and a
stale stop against a replacement session. Existing model/store and control suites
remain relevant because the prototype calls the same engine.

Before field use: two Apple IDs on two physical phones; signing and schema setup;
invite/join/revoke; denied Screen Time/location/motion/notification permissions;
enter/exit while locked and after reboot/force quit; poor accuracy; repeated motion;
start against another active profile; manual/scheduled replacement of a family
session; break/pause/stop status; offline/expired/conflicting partner requests;
notification delivery; retention and local-store upgrade. These cannot be proven
by simulator unit tests.
