# Owned session controls

Shared foundation for independently optional geofence, motion and partner controls.
Each caller supplies its own persistent key and selected Manual profile. Starting
an already-active session never adopts it. Stopping requires the exact session
created by that control, including after restart. Screen Time approval is required
for starts; existing background-stop restrictions remain in force.

No sensors, cloud entitlements, screens or permissions are added by this PR.
Existing widget/Shortcut controls continue discarding the new Bool result and omit
the optional exact-session guard. Tests cover ownership, independent controllers,
restart, strategy/auth restrictions and stale replacement stops.

The six existing Xcode path references are corrected to Foqos for case-sensitive
volumes. All feature branches depend on this foundation only, not on each other.
