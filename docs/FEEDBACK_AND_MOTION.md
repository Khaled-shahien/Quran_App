# Feedback and motion

All touch and sound feedback goes through `FeedbackService`
(`lib/core/feedback/feedback_service.dart`), registered in GetIt and provided at
the app root. Screens call `playFeedback(context, event)`; they never call
`HapticFeedback` or `SystemSound` directly.

## Defaults

| Setting (Settings → الصوت والتفاعل) | Default | Key |
|---|---|---|
| Haptics (الاهتزاز عند اللمس) | On | `feedback_haptics_enabled` |
| UI sounds (أصوات الواجهة) | Off | `feedback_sounds_enabled` |

UI sounds never affect the adhan or recitation audio.

## Events → haptic → sound

The source of truth is `feedbackMap`; a test fails if an event has no entry.

| Event | Where | Haptic | Sound (only if enabled) |
|---|---|---|---|
| `tasbihCount` | Each tasbih tap | Selection tick | System click |
| `tasbihSetComplete` | Tasbih phrase reaches its target | Double pulse (medium, 140 ms, heavy) | System click |
| `adhkarCount` | Each dhikr repetition | Light impact | System click |
| `adhkarComplete` | A dhikr reaches its count | Double pulse | System click |
| `qiblaAligned` | Phone turns to face the qibla (once per alignment) | Double pulse | None |
| `reset` | Tasbih counters reset | Medium impact | None |

## Sound specification and licences

No audio files are bundled for UI feedback. The click is the platform's own
`SystemSoundType.click`, so it follows the device's touch-sound and silent-mode
settings and needs no licence. Adhan recordings remain pending licensed files
(see the content decisions in `PRIVACY_AND_CONTENT.md`).

## Motion

- Transitions and entrances: 250–400 ms with ease-out curves
  (`fade_slide_route.dart` 350/250 ms, `AnimatedEntrance` 350 ms).
- Qibla dial eases to each sensor reading in 250 ms (`easeOutCubic`) and turns
  the short way across north.
- Press states stay fast (120 ms); the loading pulse is a slow 900 ms loop.
- Reduce motion (system setting): entrances, page transitions, the loading
  pulse, onboarding paging, the khatma progress bar, the splash bounce and the
  qibla dial all switch to instant changes.
- Not changed: the splash screen waits 2 s on every launch. Shortening it is an
  owner decision.
