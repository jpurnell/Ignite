# TestFlight — What to Test (2026-06-10)

## Adaptive Breathing Pacer

The adaptive pacer now activates in all session modes, including Quick Demo. It starts at your detected breathing rate (or the target rate if detection hasn't completed) and gradually guides you toward your resonance frequency.

**Test:**
- Start a Breathe session with Adaptive Pacer enabled in Settings
- In Pro mode, watch the "Pacer" chip — it should show your current pacing rate
- The pacer rate should gradually shift toward your configured target over the session
- Try Quick Demo mode (3s settling) — the pacer should still activate

## Glasses Coherence Feedback (Breathe Mode)

The glasses now respond to your coherence score during Breathe sessions. As coherence rises, the lens pulse amplitude decreases — the world gets calmer and clearer as a reward for resonance.

**Test:**
- Start a Breathe session with Edge glasses connected
- Observe the lens tinting — it should pulse with your breathing
- As your coherence score rises, the pulse intensity should decrease (lenses stay clearer)
- Compare early in the session (low coherence, strong pulses) vs. later (higher coherence, subtle pulses)

## Glasses Coherence Feedback (Flow/Lens Mode)

Flow mode now correctly applies coherence-based tinting when switching modes.

**Test:**
- Start a Flow session with Edge glasses connected
- Lenses should darken proportionally to coherence (low coherence = darker, high = clearer)
- Switch between Breathe and Flow modes across sessions — the glasses should respond correctly each time without needing to restart the app

## Onboarding Lens Demo

The 30-second lens demo now syncs the glasses with the on-screen animation.

**Test:**
- Go through onboarding to the "Try it — 30 seconds" screen
- With Edge glasses connected, tap the button
- The glasses should darken and lighten in rhythm with the on-screen capsule animation
- Previously they were out of phase — now they should match

## Pro Mode Stat Bar

Cleaned up to three chips: Breath (detected FFT rate), RMSSD, and Pacer (adaptive rate).

**Test:**
- Toggle Pro mode during a training session
- Verify three stat chips appear below the coherence ring
- Heart rate is no longer duplicated (it's in the header)
- "Target" chip is removed — the Pacer chip shows your current optimal rate

## Known Issues

- Xcode 27 beta: app crashes if launched with debugger attached. Launch by tapping the icon instead, or use Cmd+R (scheme configured to not auto-attach debugger).
- Edge firmware <v4.15.4: health telemetry shows `led=? duty=?` — firmware update needed for full lens state reporting.
