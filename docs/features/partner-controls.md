# Partner controls prototype

Depends only on owned-session controls. No location, motion or challenge dependency.
Select a Manual profile in Settings → Partner controls, then invite a trusted partner.

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


Unit tests cover command boundaries and owned control behavior. Signed simulator
previously showed the missing-iCloud-account error; no two-account exchange or
physical notification delivery is claimed. Validate signed-device store upgrade,
invite/join/revoke, offline conflicts and locked-phone behavior before field use.
