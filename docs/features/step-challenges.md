# Measured step challenge

Optional module atop intentional access; no geofencing, activity-start or partner
module required. Choose Steps in profile challenge settings, target 10–10,000.
Select the app, confirm your intention, then Begin step count and walk with the
phone. Only Core Motion steps after Begin count. Cancel resets challenge progress;
restart begins a new measurement. The counter ignores callbacks from older runs.
Steps taken while suspended appear when iOS resumes delivery, possibly delayed.
Motion permission is requested only when Begin is pressed. No HealthKit required.

The access button stays disabled until the measured target is met. No step data
is uploaded or persisted. If hardware/permission is unavailable or walking isn't
possible, Cancel and Stop the session; this mode never requires walking to stop.
Counts are an approximation from iPhone sensors, not anti-cheating enforcement.

Tests cover target validation/round-trip, exact threshold and inactive/stale input.
Real step calibration, suspension, denial and sensor timestamps need a physical
phone; the simulator cannot validate those behaviors. See Apple's CMPedometer
startUpdates(from:withHandler:) documentation for cumulative counting semantics.
