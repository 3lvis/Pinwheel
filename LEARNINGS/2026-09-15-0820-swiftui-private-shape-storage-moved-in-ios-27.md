**The capture engine reads SwiftUI's private shape storage by field name, so an OS bump can silently empty
it — probe the storage rather than reasoning about the symptom.** `FixedRoundedRect` carried
`cornerSize: CGSize` through iOS 26 and carries `radii: Radii` (`.uniform(CGFloat)` /
`.uneven(topLeft:topRight:bottomRight:bottomLeft:)`) from iOS 27. Reading only `cornerSize` returned nil on
27, and the three tests that went red looked unrelated to each other: a card lost its radius
(`testCardKeepsItsRadiusToken`), it lost its radius token
(`testCornerAndSpacingReferenceDesignTokens`), and the SALE badge lost its fill entirely
(`testSalePillFillSurvivesCapture`) — that last because a shape whose radius reads nil takes the
rasterizing path, dissolving the capsule and leaving white text on a light card. A throwaway test dumping
`Path.storage` for a rounded rect, a capsule and a plain rect named the change in one run, after theorising
had produced nothing. `fixedRoundedRectRadius` now reads whichever field is there, which is also what keeps
iOS 18-26 working.
*— Elvis, 2026-09-15 08:20*
