**Distribution nesting left as-is (deliberate):** the package lives in `Pinwheel/` (the Demo references it locally); a second root `Package.swift` re-exposes it for external `.package(url:)` consumers. Awkward (`Pinwheel/Sources/Pinwheel/`, two manifests) but changing it touches external import paths — not worth it now.
*— Elvis, 2026-08-18 08:36*
