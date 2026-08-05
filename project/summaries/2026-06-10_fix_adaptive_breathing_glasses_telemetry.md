# Session Summary: Fix Adaptive Breathing, Glasses Telemetry, Launch Crash

| Date | Phase | Status |
| :--- | :--- | :--- |
| 2026-06-10 | Bug Fix: Adaptive Pacer + Glasses Pipeline + Launch Crash | COMPLETED |

## 1. Core Objective

Fix the adaptive breathing pacer (never activated), sync glasses with the app's coherence and breathing data, add Edge glasses telemetry logging for auditing, and resolve the Xcode 27 beta launch crash.

## 2. Design Decisions

- **Decision:** Defer `PolarBleApiAdapter` SDK initialization to first API call
- **Rationale:** Polar SDK creates `CBCentralManager` internally, which opens an XPC connection to `blued`. In Xcode 27 beta, the bootstrap port isn't ready during App struct property initialization, causing immediate crash. Matches the `ensureCentralManager()` pattern already used by EdgeBLEScanner and HRMonitorBLEScanner.

- **Decision:** `EdgeBLEScanner` now reads settings lazily via a `settingsProvider` closure
- **Rationale:** Scanner was capturing `program`, `tintMapper`, `breatheTintMapper` at app init time. If the user switched training programs after launch, the `EdgeGlassesDevice` was built with stale settings — coherence lens mode used the breathe tint mapper, producing `perceptual=0` for `phase=idle`.

- **Decision:** Pass real coherence (not hardcoded 0) to Breathe mode glasses render stream
- **Rationale:** `BreatheTintMapper` uses coherence to modulate pulse amplitude — higher coherence = calmer lenses. Hardcoded `coherence: 0` disabled the entire reward mechanic.

## 3. Work Completed

### Commits (9 total, all on `main`)

1. **`3b9f987`** — Fix adaptive pacer activation, sync onboarding lens demo, add Edge telemetry logging
   - Adaptive pacer now activates even when `detectedBreathingRate` is 0 (Quick Demo, short settling)
   - Settling loop captures breathing rate from engine when available
   - Onboarding lens demo: `sin()` → `-cos()` so glasses match on-screen animation phase
   - `EdgeCoherencePacket` gains `pacerBpm` field (byte 17 per protocol)
   - Health log includes `ledMode`/`ledDutyPercent`; coherence log includes `respHz`/`pacerBpm`
   - Dev overlay shows "Target Rate" alongside "Pacer Rate"

2. **`70bd8e8`** — Defer Polar SDK init, recover SwiftData, use Debug scheme
   - `PolarBleApiAdapter.api` is now a lazy computed property
   - `ModelContainer` creation: on failure, deletes corrupted store and retries
   - Scheme changed from Release to Debug for development

3. **`d8cbab5`** — Fix `let` → `var` for Polar SDK protocol property assignment

4. **`78ff15e`** — Disable auto-attach debugger (Xcode 27 beta bootstrap port workaround)
   - Scheme uses PosixSpawn launcher without LLDB auto-attach
   - Workflow: Cmd+R installs/launches; Debug → Attach to Process after launch

5. **`9435950`** — Pass real coherence to Breathe mode glasses render stream
   - `FeedbackUpdate(coherence: 0, ...)` → `FeedbackUpdate(coherence: self.coherence, ...)`

6. **`4babf48`** — Add Pacer/Target rate chips to pro mode stat bar

7. **`7e5fd95`** — EdgeBLEScanner reads settings lazily via `settingsProvider` closure

8. **`42b3bc0`** — Clean up pro mode stat chips: remove redundant Heart and Target
   - Heart already in header; Target is static config value. Three chips remain: Breath, RMSSD, Pacer

9. **`eb0e790`** — Fix settings provider compile error (`State<T>?` in init)

### Key Clarification: Polar IBI Source

Devon raised concern about deriving timing from raw ECG. Not an issue — the app uses firmware-computed IBIs from the Polar SDK (`subscribeToHr` for H10, `subscribeToPpi` for optical sensors). The ECG stream (`subscribeToEcg`) is display-only for the pro mode waveform chart. The coherence pipeline never touches raw ECG data.

### Files Modified (across all commits)

- `NarbisKit/Sources/NarbisKit/Session/TrainingViewModel.swift` — adaptive pacer fix, target rate property, coherence in render
- `EdgeSDK-Swift/Sources/EdgeSDK/EdgeStatusFrame.swift` — `pacerBpm` field
- `EdgeSDK-Swift/Sources/EdgeSDK/EdgeStatusParser.swift` — parse byte 17
- `BioFeedbackKit-EdgeBLE/Sources/BioFeedbackKitEdgeBLE/EdgeGlassesDevice.swift` — enhanced status logs
- `BioFeedbackKit-Polar/Sources/BioFeedbackKitPolar/PolarBleApiAdapter.swift` — lazy SDK init
- `NarbisUI/Sources/NarbisUI/Views/DevDebugOverlay.swift` — target rate row
- `NarbisUI/Sources/NarbisUI/Views/TrainingView.swift` — stat chips (Breath, RMSSD, Pacer)
- `NarbisUI/Sources/NarbisUI/Views/OnboardingView.swift` — lens demo phase sync
- `narbis-ios/NarbisIOS/NarbisIOS/NarbisIOSApp.swift` — deferred init, ModelContainer recovery, settings provider
- `narbis-ios/NarbisIOS/NarbisIOS/BLE/EdgeBLEScanner.swift` — lazy settings provider
- `narbis-ios/.../NarbisIOS.xcscheme` — Debug config, no auto-attach debugger

## 4. Mandatory Quality Gate

NarbisKit SPM build: PASS (349 tests). EdgeSDK: PASS (109 tests). BioFeedbackKit-Polar: PASS (48 tests). Full Xcode quality-gate not run (app-layer changes require device testing).

| Check | Status |
| :--- | :--- |
| NarbisKit build + tests (349) | Pass |
| EdgeSDK build + tests (109) | Pass |
| BioFeedbackKit-Polar build + tests (48) | Pass |
| Device testing (Breathe + Flow modes) | Verified by user via Console.app logs |

## 5. Project State Updates

- Adaptive pacer bug (from memory `project_breathe_adaptive_pacer_bug`) is RESOLVED
- EdgeBLEScanner stale settings bug (from previous session handover) is RESOLVED
- Breathe mode coherence=0 hardcode is RESOLVED
- Xcode 27 beta launch crash is WORKED AROUND (debugger not auto-attached)

## 6. Next Session Handover

### Immediate Starting Point

All critical bugs from tester/App Store feedback are now fixed. The app runs on device, both Breathe and Flow modes drive the glasses correctly, and the adaptive pacer activates and adjusts.

### Pending Tasks

- [ ] OTA firmware update for Edge glasses (protocol fully documented, no implementation yet)
- [ ] Clear glasses when ConnectView finishes (dark-in-menu issue)
- [ ] Add disconnect UI for Polar and Edge glasses
- [ ] Investigate firmware session timer (`0xA4`) behavior on expiry
- [ ] Reduce BLE sync lag (breatheRenderTask interval 100ms → 50ms?)
- [ ] Edge glasses firmware v4.15.4+ needed for `ledMode`/`ledDutyPercent` telemetry (currently shows `?`)
- [ ] Consider using native firmware breathing mode (`0xB0`/`0xB1`) instead of app-side 100ms polling

### Development Workflow Note

Xcode 27 beta crashes when the debugger auto-attaches at launch. Current workflow:
- **Cmd+R** → build, install, launch (no debugger)
- **Console.app** → filter `com.narbis` for os.Logger output
- **Debug → Attach to Process** → attach LLDB after launch when needed

---

**Session Duration:** ~3 hours
**AI Model Used:** Claude Opus 4.6
