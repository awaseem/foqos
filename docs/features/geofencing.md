# Geofencing prototype

Depends only on the owned-session-controls foundation. Settings → Geofencing
selects one Manual profile and one place, radius 100–1000 m, inside or outside.
Off by default. Save a place, enable, then grant Always location. Coordinates stay
on this phone. No motion, CloudKit, partner or challenge module is required.

Return boundaries stop only this module's exact owned session and respect
background-stop restrictions. Disabling sensors does not stop an existing block.
Callbacks with unknown state or an outdated region are ignored. Screen Time
approval is required; profile selection must include the apps you want blocked.

Unit tests cover bounds and stale/disabled/unknown/inside/outside events. Physical
locked-phone boundary timing, permission denial, reboot/force quit and real shields
still require field testing. iOS delays/approximates boundary events.
