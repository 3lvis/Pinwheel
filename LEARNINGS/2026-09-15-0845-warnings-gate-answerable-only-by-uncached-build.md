**The warnings gate is only answerable by an uncached build, locally as much as in CI.** CI builds
uncached on purpose, because an incremental build skips unchanged files and never re-emits their warnings.
Running the gate's own grep over a warm build directory therefore reports zero and means nothing: the
Xcode 27 pull request read clean locally, merged, and the runner then failed the build step on
`PinCaptureLayout.swift` — `@Entry var pinCaptureSink` stores a closure, which Swift 6.4 warns may
invalidate dependents on every update since closures are not comparable, in a file the branch never
touched. Build to a throwaway `-derivedDataPath` before claiming the gate passes.
*— Elvis, 2026-09-15 08:45*
