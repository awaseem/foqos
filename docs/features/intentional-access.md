# Intentional access prototype

Independent of geofencing, activity and partner controls. Create a profile using
Intentional access, select individual apps, and save a custom reminder with {app}
as an optional placeholder. Start the session, tap its active card, then Request
temporary app access. Choose one app, confirm your intention and solve a fresh
arithmetic puzzle. A successful challenge grants 5–60 minutes for that app only,
using the existing allowance store and DeviceActivity expiry scheduler. Choose
1–10 opens per six-hour window. A failed scheduler setup rolls back the grant.

Stop remains available without completing a challenge, including if permissions
or hardware are unavailable. This is voluntary friction, not a permanent lock.
The shield never grants quick access for this strategy: on iOS 26.5 its button
opens Foqos; on older systems open Foqos manually. Input cannot live in the shield.
Category-only and web-domain challenges are not implemented; select individual apps.
Custom questions and measured steps are separate optional PRs atop this foundation.
No CAPTCHA provider, account or network request is added. Arithmetic is a deliberate
pause, not bot detection. Challenge configuration stays in existing local profile
storage and its app-group snapshots. Mac sync is disabled for this strategy because
per-app iPhone grants have no equivalent on the Mac.

Unit checks cover configuration validation, allowance compatibility/lifecycle,
stop visibility and strategy registration. Real shields, shield-to-app navigation,
expiry after lock/reboot and signed store upgrade need physical-device validation.
