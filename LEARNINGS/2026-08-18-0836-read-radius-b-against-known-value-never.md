**Read a radius by A/B against a known value, never by extrapolating one.** Edge detection on an
antialiased corner under-reads it — a known 12pt corner measured 8.3pt — so a single reading plus a
scale factor put the reference at ~19pt and would have picked the wrong token. Rendering `.radiusM` and
`.radiusL` and measuring both the same way settled it: `.radiusL` reads 12.7 against the reference's
13.0.
*— Elvis, 2026-08-18 08:36*
