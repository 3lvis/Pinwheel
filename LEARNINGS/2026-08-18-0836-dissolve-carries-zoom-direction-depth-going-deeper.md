**The dissolve carries a zoom, and its direction is the depth.** Going deeper, the tray being left
grows as it fades; coming back, the one arriving starts grown and shrinks into place. The shallower
of the two always carries the zoom and the deeper sits at 1.0, so a sequence reads as depth rather
than as a plain cross-fade. Confirmed by tracking the leading icon's x across a transition: on a push
it travels outward and on a pop it starts outward and settles back. **The zoom rides the content
alone** — chrome holds still, which is why it lives on `PinTray`'s content section through a
`PinTrayPhase` in the environment rather than as a transform on the hosted view. Measured on the
reference, its leading icon does not move a point through its own push; ours held at 34.7pt once the
transform was scoped, having drifted to 28.3 while it scaled the whole tray. The factor is 1.08,
chosen by eye — the reference's own magnitude resisted measurement because every detector saturates
on the card edge once the content fades.
*— Elvis, 2026-08-18 08:36*
