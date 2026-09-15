**The device-picker UI test, and why it is gone**

`SimulatedDeviceUITests.testSelectingSimulatedDeviceDoesNotCrash` guarded a stack overflow: an
`.animation(_:value: selectedDeviceIndex)` on the playground used to overflow SwiftUI's layout engine on
every device pick, and the decision at the time recorded that the modifier itself was the cause,
independent of the `GeometryReader`/`.position` letterboxing that was also removed.

Run again months later it failed — not on the crash, but on its own staleness: it queried a device row
that a sheet now closes over, and then the wrench, which is hidden while settings is open. Re-pointed at
liveness (`app.state`, and that the app answers any query at all) it passed. Then, teeth: the offending
modifier was put back on the playground and **it still passed**. It cannot fail for the reason it exists,
so it was guarding nothing, and it had been guarding nothing silently — `DemoUITests` is not in the merge
gate, so nothing ran it.

Deleted rather than repaired. If the crash returns, it returns against a playground that no longer has
the geometry the original one had, and a new guard should be written against whatever actually
reproduces. `DemoUITests` is empty at rest again, which is what the rungs table says it should be.
*— Elvis, 2026-08-18 08:36*
