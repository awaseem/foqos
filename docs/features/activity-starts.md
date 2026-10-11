# Activity starts prototype

Depends only on the owned-session-controls foundation. Settings → Activity starts
selects one Manual profile; enabling starts it on confident walking, running or
cycling. Stationary/vehicle/low-confidence events never stop it. Off by default;
Motion access is requested only after opt-in. No geofence or cloud module required.

Motion callbacks pause while the app is suspended and resume on reopening. This
cannot reliably start blocking on a locked phone. Disable before choosing another
profile. Stop affects only this module's exact session; disabling sensing leaves
an existing block active. Screen Time approval and a selected-app profile required.

Tests cover disabled/low-confidence/stationary states and all three activity starts.
Real motion hardware, denial and suspension need physical-device testing.
