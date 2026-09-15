**The motion and the metrics are measured, not guessed.** Frame-stepping a 60fps capture of X's tray:
the height settles a ~377pt move in ~0.23s and an ~87pt move in ~0.15s, with about 3pt of overshoot on
the big one only. Duration scaling with distance is a spring rather than a timed curve, hence
`springDuration: 0.30, bounce: 0.10`. The same capture gives the geometry, and the tray is a **floating
card**, not an edge-to-edge sheet: an 8pt margin on all four sides (`.spacingS`), continuous corners,
everything inside inset `.spacingXL`, a 64pt header band (which Pinwheel
already had), a 1pt hairline, and a 48pt commit button whose bottom lands 32pt off the screen. Ours
matches every one of those.
*— Elvis, 2026-08-18 08:36*
