**Everything SwiftUI hands over mid-move is news, not an instruction — one rule, not one guard per
value.** Two values arrive about the tray that is *arriving*: how it stands (`fillsReported`) and how
tall its content measures (`contentResized`). Drawing either one while the outgoing tray is still on
screen puts the arriving tray's shape in the outgoing tray's place. Guarding them one at a time is how
the dip kept coming back: the first guard went on `fillsReported`, `contentResized` kept drawing, and
every push collapsed 641 → 245 → 828. `recordForTheArrivingTray` now catches all of them at the top of
`handle` while `isSettlingAMove`, and the move's resolution draws once. Measured across the whole loop
— present, push, pop, push — every leg is 187pt of travel for 186pt of distance with no reversals,
where two of them previously wasted 52pt and 477pt.
*— Elvis, 2026-08-18 08:36*
