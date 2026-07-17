# Companion Device Protocol

Foqos can push live blocking-session status to an external "companion device"
over Bluetooth LE and accept session toggle requests from it. The feature is
**opt-in and dormant by default**: no `CBCentralManager` is created (and no
Bluetooth permission prompt appears) until the user enables it in
Settings → Companion Device.

Any hardware that implements the peripheral side of this contract works —
e.g. a microcontroller with a display, optionally carrying an NFC tag. This
document is the canonical contract; firmware implementations live outside
this repository.

## Roles

- **Foqos (iOS)**: BLE central. Connects, writes status, subscribes to toggle
  requests. Uses CoreBluetooth state restoration so reconnection and toggle
  handling survive backgrounding.
- **Companion device**: BLE peripheral. Advertises the service below, renders
  status, optionally sends toggle requests (e.g. from a button or touch
  screen).

## GATT service

Device name: `Foqos Companion` (advertised). Service UUID:

```
F0C50001-8B1E-4B6D-9F26-3F0B5C7A1D01
```

| Characteristic | UUID (`F0C5000x-…`) | Direction | Payload |
| --- | --- | --- | --- |
| Status | `…0002` | app → device (write) | packed status, below |
| Time sync | `…0003` | app → device (write) | `i64` current epoch seconds, LE; written on every connect (device may lack an RTC) |
| Tag config | `…0004` | app → device (write) | UTF-8 profile deep-link URL (≤128 B) for devices carrying an NFC tag; a zero-length write clears the tag |
| Toggle | `…0005` | device → app (notify) | `u8` monotonic counter; each notification asks the app to toggle the session. The app uses the counter to drop retransmits, so devices should increment it per tap |

## Status payload (little-endian, fixed offsets)

Version 2, 102 bytes:

| Offset | Type | Field |
| --- | --- | --- |
| 0 | `u8` | version (= 2) |
| 1 | `u8` | flags: bit0 active, bit1 break, bit2 pause |
| 2 | `i64` | session start, epoch seconds (0 = none) |
| 10 | `i64` | expected end, epoch seconds (0 = open-ended) |
| 18 | `u8[64]` | profile name, UTF-8, null-padded, truncated at a scalar boundary |
| 82 | `u16` | focus streak, days |
| 84 | `u32` | today's focus time, seconds |
| 88 | `u16[7]` | focus minutes per day, oldest first, `[6]` = today |

Version 1 is the same layout truncated at 82 bytes.

### Versioning

The payload is append-only: a new version only adds fields after the existing
ones and bumps the version byte; existing offsets never change. Devices MUST
accept any version greater than or equal to the one they were built for,
parse the prefix they understand, and treat fields beyond the received length
as zero. A parser that requires an exact version match breaks on the next
release.

## Behavioral contract

- The app writes status **on session state changes** (start/stop/break/pause),
  on reconnect, and on app foreground — not continuously. Devices with timers
  must count down/up locally from the epochs plus the time-sync value.
- Timer expiry is **not** pushed in real time (iOS may not be running);
  devices flip to inactive locally when `expectedEndEpoch` passes and
  reconcile on the next write.
- The app re-pushes current status after every (re)connection; devices may
  treat RAM state as disposable.
- Toggle semantics: active session → stop (subject to the profile's
  `disableBackgroundStops`); no session → start the profile the user selected
  in the companion settings. The app debounces notifications delivered within
  1.5 s and drops repeats of the last counter value within 30 s.
- Toggle requests are fire-and-forget; devices should show a pending state and
  revert after ~10 s if no confirming status write arrives.

## Security

The link is deliberately unauthenticated and unencrypted. BLE
bonding/pairing is out of scope: the payload carries no secrets (session
flags, epochs, a profile name, aggregate focus stats), and requiring bonding
would exclude hobbyist hardware without persistent key storage. Anyone in
radio range can read status writes or send toggle notifications; the blast
radius is bounded because toggle requests go through the same path as in-app
actions — a profile with `disableBackgroundStops` ignores stop requests, so a
nearby attacker cannot break a locked focus commitment. The worst case is
starting a session, or stopping one whose profile already allows background
stops. Implementations that want more can layer BLE bonding on the same GATT
service without changing this contract.

## Swift surface (for maintainers)

`CompanionDeviceManager` (Utils) owns the BLE session; `CompanionStatusPayload`
(Models) is the pure, unit-tested encoder; `StrategyManager` calls
`pushStatus`/`pushSessionEnded` at its existing lifecycle points, mirroring
`LiveActivityManager`. Payload byte layout is locked by golden-vector tests
(`foqosTests/CompanionStatusPayloadTests`) that firmware decoders can share.
