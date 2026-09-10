# Pinwheel — learnings

Why things ended up the way they did: the measurements, the traps, and the fixes that only make sense
once you know what broke. `AGENTS.md` holds the rules you need in every session; this holds the ones you
need when you are about to change the thing they are about. Append, never rewrite.

## Trays


- **A tray is a short surface that stands as tall as its own content, and a sequence of them is one
  surface changing.** `PinTray` is the content — centred title, one leading control, optional trailing
  accessory, optional commit — and `View.pinwheelTray(path:)` is the stack, where the array *is* the
  navigation: appending pushes, removing pops. The leading control is **derived from depth**, a cross at
  the root and a back chevron once pushed, so a root tray showing "back" is unrepresentable. Modelled on
  the tray system Benji Taylor built for Family and now X, whose published rules we follow: one piece of
  content or one action per tray, every tray titled, consecutive trays differing in height, and the theme
  taken from context.
- **The chassis is hand-written UIKit hosting SwiftUI, because neither `presentationDetents` nor
  `UIPresentationController` will give up the height.** A detent is a declared *set of stops* that UIKit
  re-resolves with its own animation, so the sheet edge can't be put on the same timeline as the content;
  and a presentation controller re-applies `frameOfPresentedViewInContainerView` on the next layout pass,
  which cancels a spring started against it. The tray therefore owns everything: its own view in the
  topmost controller's hierarchy, a height constraint, a dimming view, and one
  `UIView.animate(springDuration:bounce:)` driving the height and the cross-dissolve together.
- **The overlay hangs off the topmost view controller, never straight off the window.** A
  `UIHostingController`'s view has to live inside its parent controller's own view tree; parenting the
  hosting controllers to the presenter while adding their views to the window raises
  `_associatedViewControllerForwardsAppearanceCallbacks` and kills the app on first present. Walking
  `presentedViewController` to the top also puts the tray above whatever is currently presented.
- **`UIHostingController` already applies the bottom safe-area inset, so the chassis sets
  `safeAreaRegions = []` and adds it once.** Leaving both to apply it measures it twice and leaves a
  second inset of dead space under the content — 67pt below the commit button where the reference has 32.
- **The motion and the metrics are measured, not guessed.** Frame-stepping a 60fps capture of X's tray:
  the height settles a ~377pt move in ~0.23s and an ~87pt move in ~0.15s, with about 3pt of overshoot on
  the big one only. Duration scaling with distance is a spring rather than a timed curve, hence
  `springDuration: 0.30, bounce: 0.10`. The same capture gives the geometry, and the tray is a **floating
  card**, not an edge-to-edge sheet: an 8pt margin on all four sides (`.spacingS`), continuous corners,
  everything inside inset `.spacingXL`, a 64pt header band (which Pinwheel
  already had), a 1pt hairline, and a 48pt commit button whose bottom lands 32pt off the screen. Ours
  matches every one of those.
- **The type scale is 20/18/16, taken from the reference.** `PinwheelDefaultFontProvider` was 23/20/17; measuring
  X's tray gave an ~18pt semibold title, ~16pt body and row text, and a 20pt semibold price, which is a
  cleaner three-step scale and is what the default theme now ships (footnote 13 and caption 11 unchanged).
  `PinwheelFontProvider`'s semibold defaults hardcode their sizes rather than deriving them from the regular
  variants, so a scale change has to be made in both files or the weights drift apart.
- **The card's bottom corners take the display's own radius, and the top pair does not.** A
  bottom-anchored card reads as continuous with the hardware only when its bottom corners carry the
  screen's radius outright — `UIScreen`'s `_displayCornerRadius` (62 on an iPhone Air), read by KVC
  since UIKit exposes it nowhere public. Note it is *not* the concentric `radius - inset`: 54 was
  measurably too tight, and matching the reference's corner profile point by point picked 62. The top
  corners sit nowhere near a device corner and stay small (28). `CALayer` carries one radius, so the
  card is two nested layers — an outer rounding only the bottom pair, an inner rounding only the top —
  which keeps both animating natively with the height, where a `CAShapeLayer` mask would have to be
  animated by hand. Both set `cornerCurve = .continuous`, matching `ConcentricRounding`'s existing
  vocabulary; a circular corner reads as cut against the device's curve.
- **A card standing clear of the bottom edge loses the display's radius.** With the keyboard up the
  tray rides above it, is no longer nested in the display's corner, and its bottom pair drops to the
  same radius as its top — measured on the reference, the two corners are then identical. The overlay
  watches `keyboardWillChangeFrame`, lifts by the overlap, and animates the corner with the keyboard's
  own duration and curve so the two move as one.
- **The spacing in the reference is 8 between things and 24 around them — there is no 20, and 24 is
  never a gap.** Measured across 433 unique frames of X's tray: adjacent boxes are 8pt apart (159
  occurrences, plus 29 at 9 and 3 at 7, and *nothing* at any other value), content is inset 24pt from
  the card edge (603 occurrences), and a control is 48pt tall (447). The large separations between
  sections are 70-100pt and are not spacing at all — they are content sitting in the gap. So a middle
  step between `.spacingL` and `.spacingXL` has no support: the scale in evidence is 8 / 16 / 24 / 48.
- **The tray's bottom clearance is the home indicator's, not a spacing token.** It reads as 24pt on an
  iPhone Air, which is the bottom safe area less the margin the card already stands off the screen by —
  so the tray derives it (`safeAreaInsets.bottom - trayBottomMargin`, floored at `.spacingL`) and the
  content's bottom lands exactly on the safe-area boundary on any device. Lifted onto the keyboard
  there is no indicator to clear, so it drops to the floor. Hardcoding 24 would be right on one phone.
- **A tray clears the keyboard by more than it clears the screen edge.** `.spacingL` above the
  keyboard against `.spacingS` above the bottom of the display — the reference measures 20pt there, and
  the token is taken over the exact number. The overlay carries both, and
  recomputes its ceiling when the keyboard moves so a tray that fills shrinks to the new room rather
  than being pushed off the top.
- **The hosted content is held at its own height from the top, never stretched to the card.** Pinning
  its bottom to the card as well re-lays the content out on every frame of the height spring, and a
  cross-fade between two reflowing views reads as a stutter rather than a dissolve. Measured after the
  fix: the body's first ink sits a constant 192.3pt below the card's top for the whole transition while
  the card springs 264 -> 402pt. The constraint stays updatable so a filling tray still re-lays out when
  the keyboard moves.
- **A standing tray's content is live, and its height follows.** The presenting view re-renders on its
  own state, so an unchanged path still has to hand the standing tray freshly built content — without
  that, a tray keeps rendering whatever it was mounted with, and a search field types into a list that
  never filters (the same graph boundary that breaks `@FocusState`). The height then follows from
  SwiftUI's side: the content is `.fixedSize(vertical:)` so it reports its *ideal* height rather than
  the box it was put in, and an `onGeometryChange` hands that back to the chassis, which springs the
  tray to it. Watching the hosted view's `intrinsicContentSize` from `layoutSubviews` does **not**
  work — a required height constraint means nothing in the overlay's own layout is dirtied, so it
  fires only at mount.
- **A tray about to edit hands its timeline to the keyboard; one that is leaving dismisses it
  deliberately.** Two faults with one cause — geometry resolved at a moment when the keyboard's state
  was not yet true. Pushing to a tray that edits, the card shrank to its new height with no keyboard
  under it yet, so its top fell 184pt to the floor and climbed back once the keyboard arrived. So the
  push now waits a turn, asks whether anything in the tray became first responder, and if so leaves the
  height for the keyboard to carry: the constant is set from `layoutSubviews` when the guide moves, so
  it resolves inside the keyboard's animation. Measured, the top then runs 262 -> 103 without ever
  reversing. Popping, unmounting the tray tore the field out from under the keyboard and it vanished
  with no animation to travel with, so the card descended alone; `endEditing(true)` before the
  transition gives the keyboard its own dismissal to ride, and the card goes 103 -> 262 beside it.
  The dissolve stays on its own timeline in both directions — it is the content changing, not the card
  moving, and it should never wait on a keyboard.
- **Measure a transition from inside the app, not from a recording.** A `CADisplayLink` writing the
  tray's presentation-layer frame and the guide's frame to a file each frame answered in one run what
  four rounds of pixel-detectors on `simctl` video could not: the detectors kept latching onto the
  keyboard's edge or the content behind the tray, and `simctl io recordVideo` drops the very frames a
  transition lives in. Read the file out of the app container afterwards. Note the guide reports its
  *model* value, so it shows the keyboard's target rather than where it is drawn — for that, look at
  frames.
- **The keyboard lays the tray out; the tray does not react to the keyboard.** On iOS 17+ the keyboard
  runs in its own process and "will *asynchronously* initialize the keyboard UI and then
  *asynchronously* post the notifications and perform the animations" (WWDC23, *Keep up with the
  keyboard*) — so anything driven off `keyboardWillChangeFrame` is racing an animation it cannot join,
  which is why our own spring read as staggered no matter how it was tuned. The tray constrains its
  bottom to `keyboardLayoutGuide.topAnchor` with `usesBottomSafeArea = false`, and hands the two
  margins to `setConstraints(_:activeWhenNearEdge:)` / `activeWhenAwayFrom:` so UIKit swaps them inside
  the keyboard's own animation. Interactive dismissal comes free — the guide tracks the dismiss gesture.
  **Never toggle those constraints by hand from `layoutSubviews`**: it re-enters layout and UIKit throws
  `_setActive:mutuallyExclusiveConstraints:`. Only the corner radius is read there, because a corner is
  not expressible as a constraint.
- **Leaving a tray that was editing, the card takes its resting place at once and the keyboard slides
  off it.** Studied frame by frame, the reference never squeezes a card into the room a departing
  keyboard still occupies and never walks it down: at the moment back is tapped the full-height card is
  already at the screen's bottom, *behind* the keyboard, and the keyboard alone moves, uncovering it.
  One moving object rather than two is what makes it read as a single motion. A required `rest`
  constraint pinned to the view's bottom, activated on a pop and released when the transition ends,
  outranks the guide's own (priority 999) for exactly that span.
- **The keyboard is measured from the edge the card is pinned to, and the margin above it comes from one
  place.** The card's bottom is a constraint to `keyboardLayoutGuide`; its height is the machine's. Two
  disagreements between them left the top drifting 26pt as the keyboard went, which reads as the card
  sliding down while you scroll. First, `measuredKeyboardHeight` subtracted the bottom safe area that the
  guide already excludes (`usesBottomSafeArea` is false), so the machine believed a 345pt keyboard was
  311 and made the card 26pt too tall. Second, one constraint serves both a docked keyboard and no
  keyboard at all, so a fixed margin on it is right for one and wrong by 8 for the other — `offset.constant`
  is now whatever the geometry keeps clear beyond the keyboard itself. Measured with a live keyboard,
  the top went 90 → 124 → 116, where 116 is `safeAreaTop + trayBackdropReach` and is what the model said
  all along. Teeth: reverting both puts it back to 90 on the same probe.
- **A reaction that changes nothing starts nothing.** Dragging the list to put the keyboard away, every
  sample arrived twice — once as moving, once as apparently settled — and the settled one started a
  spring against a keyboard still under the finger, sixty times a second. The model said the card's top
  was at 117 throughout; the layer sat at 90, dragged up by the springs in flight, and snapped back when
  they stopped. An interactive dismissal never really settles, so "same height twice" is not a test for
  it — whether anything actually moved is. `handle` compares each reaction against what is already drawn
  and hands back `carriedByKeyboard` when they match.
- **An arriving tray is the size of the card it is arriving into, however tall it measures.** Returning
  to the search tray with a query still typed, its content measured 1553 against a 641 card, the chassis
  laid it out at 1553, and the card became a window onto nothing — blank. Shorter than the card and
  anything anchored to the content's bottom floats mid-card; taller and the card shows nothing. Only a
  tray that has arrived and is sized by what it holds keeps its own height, which is what the chassis
  scroll exists for.
- **A session someone drove by hand is readable: `-PinwheelRecord`.** `PinwheelRecorder` writes
  `session.log` into the app's temporary directory — every touch with the identifier of whatever it hit,
  every navigation, everything SwiftUI reports in, every reaction the machine returns, and the geometry
  between them (only when it changes, so sitting still costs nothing to read). Touches come from a
  `UIGestureRecognizer` that never leaves `.possible`, so it sees everything and swallows nothing; it
  attaches to each window on `didBecomeVisibleNotification`. Off entirely without the argument. It exists
  so a person can say "watch this" instead of describing it — and because a description of motion is the
  thing this repo keeps proving you cannot act on. **Each launch truncates the file**, so read it before
  relaunching.
- **The arriving content is laid out to the card, never to itself.** The chassis mounted an arriving
  tray at its own measured height and `write` kept re-setting it there — 245 inside a 642 card — so the
  search field, which rides the content's bottom edge, appeared mid-card and travelled down once the move
  resolved. The card's own geometry was clean throughout, which is why every tape of the *card* said the
  push was fine: 794pt of field travel, invisible in the column being sampled. `currentHeight` is now
  `max(fittedHeight, geometry.height)` — taller than its card it keeps its height and scrolls, shorter it
  stretches to fill — and the field's bottom edge no longer moves at all during a push. `settleGeometry`,
  a second place that drew the same constant and had no callers left, is gone with it.
- **No tray ever covers the space that dismisses it.** Tapping the backdrop above the card dismisses the
  whole tray, so `trayBackdropReach` reserves a strip of it — `.minimumControlHeight`, because tapping it
  is a control and takes a control's target size. A filling tray taking *all* the room left 8pt between
  the safe area and the card: measured, a tap aimed at that strip landed on the card instead, and the
  header became the only way out. The room every tray is clamped to is now measured from below that
  strip, which costs 40pt of height and buys back the affordance.
- **Everything SwiftUI hands over mid-move is news, not an instruction — one rule, not one guard per
  value.** Two values arrive about the tray that is *arriving*: how it stands (`fillsReported`) and how
  tall its content measures (`contentResized`). Drawing either one while the outgoing tray is still on
  screen puts the arriving tray's shape in the outgoing tray's place. Guarding them one at a time is how
  the dip kept coming back: the first guard went on `fillsReported`, `contentResized` kept drawing, and
  every push collapsed 641 → 245 → 828. `recordForTheArrivingTray` now catches all of them at the top of
  `handle` while `isSettlingAMove`, and the move's resolution draws once. Measured across the whole loop
  — present, push, pop, push — every leg is 187pt of travel for 186pt of distance with no reversals,
  where two of them previously wasted 52pt and 477pt.
- **A tray's shape arrives as state, never as its own animation.** Wiring `fills` up from the tray's
  preference, its `didSet` also drew the change — `settleGeometry(animated:)`, a second animation path
  the machine knew nothing about. It fired when the preference landed, which is *before* the keyboard,
  so the card grew to the floor and then climbed back: measured, the top went 262 → 602 → 76, one
  reversal and 340pt of wasted downward travel, which is exactly the shoot the awaiting-keyboard hold
  exists to prevent. The flag is now only recorded and the next event carries it; the same run then
  reads 262 → 76, monotonic, no reversal. Any `didSet` that draws is this bug again.
- **A tray is as tall as what it holds, or as tall as the room there is — `.fitting` or `.filling`.**
  `.medium` was a lie once it stopped being half of anything, so the pair now says what it means. A
  filling tray is anchored by its **top**, which makes that top a constant (`safeAreaTop + trayMargin`)
  no keyboard can move: only the bottom travels, riding the keyboard down and clamping at the floor
  while the keyboard carries on past it. That is what stops the card shooting when the search field is
  tapped again — it is structural, not arranged. Guarded by
  `testAFillingTrayKeepsItsTopWhereverTheKeyboardIs`, which sweeps the keyboard 311 → 0 → 311 and asserts
  one distinct top; with the anchor removed it walks 585 → 904 → 585.
- **The chassis scroll is a rescue, not a scroller, so a filling tray turns it off.** The overlay wraps a
  tray in a `UIScrollView` so a *fitting* tray clamped by the room scrolls rather than clips. A filling
  tray is exactly as tall as its card, and leaving that scroll enabled hands it the drag meant for the
  content — measured: dragging the results carried the header and separator up off the top of the card.
  It is disabled the moment the tray says it fills.
- **A search tray is header, rule, scrolling list, and a search field floating over the list at the
  bottom.** The field sits where the thumb is and never scrolls away, the list runs on underneath it
  (`.contentMargins(.bottom,)` so the last row is still reachable), and `.scrollDismissesKeyboard(.interactively)`
  gives the keyboard back to a downward drag. A tray declares that it fills through `PinTrayFillsKey`,
  and the room it currently has arrives on the observable `PinTrayPhase` — not the environment, so the
  keyboard moving re-renders the content without rebuilding it.
- **A tray leaves on the keyboard's clock, not after it.** Tapping the space above an editing tray
  dismisses the whole tray — one meaning per control, and backing out of a sheet should not depend on
  which part of the backdrop was hit. Its motion used to be three reactions fighting inside 24ms: the
  keyboard's report said *rest*, the dismissal said *leave* against a keyboard already sent away, and a
  second report said *rest* again and won — so the card lurched two thirds of the way down and was
  deleted off the screen mid-air (measured: top 103 → 445 of 912, removed at 0.335s). Now leaving is
  sticky (a report cannot put a leaving tray back), the exit is measured with the keyboard gone, and it
  is drawn on the duration and curve the keyboard announces in `keyboardWillShow`/`Hide` — so the two
  start together and stay on one curve instead of handing off, which is where a stall comes from. The
  keyboard's real duration is **0.3833s**, not the 0.25s everyone assumes: borrow the clock, never guess
  it. `PinTrayMachine.Timeline.matching` carries it, and the unmount waits for that same duration.
- **An effect the machine commands counts as having happened, that same turn.** Coming back from the
  search tray landed the card at 509pt — a height belonging to neither tray. The reaction was computed
  while the keyboard was still up and applied *after* `endEditing` had already re-laid the screen, so the
  keyboard's own reports landed first and the stale answer overwrote them. Dismissing is therefore a
  change to the machine's own state (`keyboard = .closing`) at the moment it is ordered, not when the
  keyboard gets around to confirming it — which makes the outside world's confirmation agree with what we
  already drew, so arrival order stops mattering. Two tests hold it, one for the height and one for the
  ordering.
- **The view measures the keyboard; the machine decides what the measurement means.** The overlay used to
  keep its own `keyboardInset` and derive opening/open/closing from it, updating it only when the machine's
  view of the keyboard changed — so a *commanded* dismissal left the copy stuck at 311 forever. The next
  push then read a rising keyboard as already settled, ran our spring against its animation, and the card
  sagged 40pt before climbing (measured: one reversal on the second push, none on the first). The copy was
  the bug, so it is gone: the view reports a height and `PinTrayMachine.keyboard(measuring:)` draws the
  conclusion. Structural, not asserted — there is no second copy left to go stale.
- **The tray is a machine, and the keyboard is an actor it does not own.** `PinTrayMachine` holds the
  state — what the tray holds, what the keyboard is doing, whether the standing tray edits, a drag —
  and answers each event with where the tray goes *and who moves it there*. That last part is the one
  every bug turned on, so `Timeline` is state: `.immediate` for an entry position or a finger,
  `.spring(bounce:)` for a change nothing else owns, and `.carriedByKeyboard` for one the keyboard owns,
  where we set the value and start nothing. The keyboard enters as **reports** (`closed`, `opening`,
  `open`, `closing`) mapped from the guide rather than as something we command, because we cannot
  command it — and `opening`/`closing` are exactly the states in which it owns the timeline. Effects it
  cannot perform itself, like dismissing the keyboard on the way out, come back as `Effect` values.
  Every rule is then a test with no window: twelve of them, each named for the state that broke.
- **"Hold still" has to mean holding the old value, not the new one with the animation withheld.** The
  first machine correctly said the keyboard owned the push, and still handed out a target computed with
  the keyboard closed — the floor. The test that walks the whole journey and asserts the top never
  reverses caught it: `[263, 448, 129, 129]`, with the dip sitting in the middle of the model. A tray
  waiting for the keyboard keeps the height it is standing at until the keyboard reports.
- **The tray's geometry is a value, and the views are a projection of it.** `PinTrayGeometry` takes
  what the tray holds, the room, the keyboard, a drag and a phase, and answers height, clearance,
  translation and corner — importing `CoreGraphics` and nothing else. Every rule discovered by filming
  the reference is a plain test there (12 of them, 8ms, no window), and the chassis reads it in one
  place and applies it in one closure. The bug that forced this: a transform assigned before the
  animation rather than inside it, so a tray arrived already in place — invisible to every test, and
  only findable by asserting on a `CALayer` animation key, which is testing the mechanism. With the
  geometry extracted, "a tray arrives from below its own bottom edge" is a value comparison, and the
  one place that applies it can no longer put half the state outside the animation.
- **One geometry, one animator — a second curve on the same constraint reads as two steps.** The
  card's height, how far it stands off the bottom, and its bottom corner are one state, settled by one
  spring that every trigger re-targets. Leaving a tray with the keyboard up used to run our spring and
  UIKit's keyboard curve over the same constraints at once, and the second replaced the first
  mid-flight: the dismissal read as chained rather than continuous. The keyboard no longer brings its
  own curve.
- **Navigation is felt, content is not.** A push or pop springs with bounce and carries the zoom;
  content resizing inside a standing tray moves the height alone, with `bounce: 0`, because an
  overshoot there reverses direction under someone who is reading.
- **A surface you browse stands at a detent; only a surface you read is sized by its rows.**
  `PinTray.Detent.medium` takes half the screen (clamped by the room) and keeps it whether or not the
  keyboard is up, so a list that filters as you type scrolls inside a still card. Measured on a search
  that made a reviewer motion sick: the card's top edge travelled 13,174pt across 45 direction
  reversals, and after these three changes travels 198pt across 1.
- **The dissolve carries a zoom, and its direction is the depth.** Going deeper, the tray being left
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
- **A clamped tray scrolls, and a dissolve runs against a still picture.** Content is held at its full
  height inside a scroll view, so a tray that outgrows the room scrolls instead of clipping; the tray
  it is leaving is snapshotted and faded, which keeps the scroll view holding a single live tray and
  guarantees neither side of the dissolve can re-lay itself out.
- **A tray is sized by its content, and nothing else — there is no fill.** More content, taller tray;
  less content, shorter one, down to a floor of the 48pt control plus the header's and the commit
  button's own spacing. The available room is a *clamp*, never a target: a tray is measured against an
  unbounded height and only capped when it would outgrow the screen or the keyboard. A search tray was
  briefly made to fill the room the way the reference's does — the reference's stands 477pt tall with
  roughly half of it blank — and that is a divergence we take deliberately, because a tray that
  reserves space it has no content for is a tray lying about what it holds.
- **`@FocusState` does not cross a hosting controller.** A tray's content renders in its own
  `UIHostingController`, so focus declared on the presenting view silently never takes and the keyboard
  never comes up; the field has to own its own `@FocusState` inside the tray's content. The symptom is
  a text field that looks right, takes a tap to focus, and shows no caret on arrival.
- **The top radius is 32.** Measured against the reference's corner profile; `.radiusL` (24) and a
  first guess of 28 were both visibly tighter at every depth. Not a radius token.
- **Compare a corner by its profile, not by one number.** "How far along the edge until it goes
  straight" saturates and inverted the answer here — it said the reference corner was *smaller* than
  ours when it was larger. Sampling the edge inset at a series of depths (4, 8, 12, 16, 24, 32, 40,
  48pt from the corner) compares two curves honestly and solved the radius in one run.
- **Read a radius by A/B against a known value, never by extrapolating one.** Edge detection on an
  antialiased corner under-reads it — a known 12pt corner measured 8.3pt — so a single reading plus a
  scale factor put the reference at ~19pt and would have picked the wrong token. Rendering `.radiusM` and
  `.radiusL` and measuring both the same way settled it: `.radiusL` reads 12.7 against the reference's
  13.0.
- **A rule is drawn in `tertiaryText`, the faintest foreground token — a separator is not its own
  token.** The palette is nine role tokens and stays nine: adding a `divider` beside them would be a
  token per use, which is a list of colours rather than a system. `secondaryBackground` (242 on white)
  was too faint to read at 1pt, so the hairline in `PinTray` and
  `UIPinTableView`'s `separatorColor` all take `tertiaryText`. One rule colour, already in the
  vocabulary.


## Theme & shared vocabularies


- **Theme is law.** Every surface resolves provider-backed tokens (a `PinwheelTheme`'s `PinwheelColorProvider`/`PinwheelFontProvider`), never Apple's system styles. API is designed so the wrong (system-style) path is unrepresentable.
- **A theme is a named value in the environment, plural by default.** `PinwheelTheme` is a `struct` (name + the two providers), supplied as `PinwheelCatalog(themes:)` and resolved through `EnvironmentValues.pinwheelTheme`, bridged to a `PinwheelThemeTrait` (`UITraitDefinition`) so UIKit-hosted items and the FAB's own window resolve the same selection. It replaced the single static `Config.colorProvider`/`Config.fontProvider` pair, which nothing observed — assigning it re-rendered nothing, so one catalog could only ever show one brand. Two or more themes put a palette picker in the toolbar beside the appearance menu; the selection persists (`Pinwheel.SelectedThemeName`) and a deep-link preview honours `-PinwheelPreviewTheme <name>` so a sweep captures each brand. Themes are `Equatable` **by name** — the providers are a theme's contents, not its identity.
- **A theme carries component shape, not only tokens.** `PinwheelTheme.buttonShape` (`.rounded` / `.capsule`) exists because a silhouette is as much a brand's signature as its palette, and a capsule is half the button's height — a `CGFloat` corner radius cannot express one, which is why `RoundedRectangle(cornerRadius: .spacingM)` was hard-coded in `PinButtonStyle` before. The case stores *intent* and `PinButtonShape.shape` resolves the token at render, so a theme states what it wants and the render decides what that measures. It stays a lone property rather than a `components` bag until a second component needs one.
- **Spacing and radius are constants, and stay global rather than per-theme.** `CGFloat.spacing*` / `.radius*` are `static let`. They were `static var`s forwarding to mutable `SpacingValues`/`RadiusValues` backing structs — the package's only mutable static state, publicly settable, observed by nothing, and assigned by nothing in the package, the Demo, or the tests. The whole indirection was dead configuration, so both backing structs went. They stay global on purpose: the design system Pinwheel is being built for generates one spacing scale across its brands and varies only *component* metrics, which is what `buttonShape` is for.
- **A custom trait must declare `affectsColorAppearance` or dynamic colors go stale.** `UIKit` re-resolves a `UIColor(dynamicProvider:)` only for traits that say they change color appearance, and the default is `false` — so `PinwheelThemeTrait.affectsColorAppearance = true`. Without it a switch leaves views on the theme they were last drawn under, and the giveaway is a *mixed* result: a `backgroundColor` re-resolved while a `tintColor` assigned earlier did not, so the FAB showed one brand's wrench beside another brand's close. Guarded by `testSwitchingThemeCountsAsAColorAppearanceChange`, which asserts `hasDifferentColorAppearance(comparedTo:)` across two themes rather than the flag itself.
- **A sheet or cover takes its traits from the window, so the theme is written there.** The theme environment value is trait-bridged, which means SwiftUI reads it back out of the UIKit trait collection — and a presentation's traits descend from the window rather than from the view that presented it. Applying `.environment(\\.pinwheelTheme,)` to sheet content therefore does nothing: measured, the playground held `Ember` while the settings sheet inside it resolved `Standard`. `PinwheelThemedWindow` writes `traitOverrides` on the catalog's own window (never the scene, so an embedded catalog can't theme its host), which every presentation then inherits. `PinwheelPreview` resolves its chrome in `init` rather than `onAppear`, or the window override lands before the requested theme is known. Guarded by `PresentedThemeTests` in the hosted `DemoTests`, which needs an app because the failure only exists across a real presentation. **The window carries the brand's tint as well as the trait**, because the chrome the system presents for us — a `UIAlertController` above all — colours its buttons from `tintColor` and reads no trait of ours, so under a branded theme it drew Apple's blue. That one is guarded by structure rather than a test: one method writes trait and tint at both moments a window can arrive (the probe joining a window, and a later selection), so neither can land without the other and a host needs no tinting code of its own.
- **The display axes live in a native bottom toolbar; a presented item keeps the FAB.** Section, theme and appearance are global display axes, so they sit in `ToolbarItem(placement: .bottomBar)` — which on iOS 26 the system renders as glass capsules floating over scrolling content, split by `ToolbarSpacer` (guarded, since it is iOS 26 only). The section reads as text on the left, theme and appearance as SF Symbols grouped on the right, and the index carries no navigation title because the bar states it. Reaching the top of the screen and looking back down was the complaint; the bottom is also where iOS 26 moved system search, for one-handed reach. **`Menu` content cannot be themed but a toolbar item's can** — `Button("Tokens")` renders system sans, `Button { } label: { PinLabel("Tokens") }` takes the theme, which is why the pickers are sheets while the bar is native. A presented component has no `NavigationStack` of ours to hang a toolbar on, so it keeps the draggable FAB and its settings sheet.
- **Every bottom sheet is a tray, and a tray's title bar is the one chassis.** `PinwheelSheet` and `PinwheelSheetModel` are gone: the catalog's own pickers — section, theme, appearance — and the tweak flow with its pushed device list are all `pinwheelTray(path:)` sequences, so the leading slot that always means get out (a cross at the root, a back chevron once pushed), the centred title, and the trailing accessory that holds the device button are the tray's rather than a second chassis's. The title bar stands at the 48pt control floor with one spacing-1 each side, so **56pt** — the sheet it replaced used spacing-2 for 64pt, and the tray's tighter band is the one that shipped. Both paddings stay the same token because an asymmetric pair left the title off-centre in its own band. Guarded by `TrayHeaderHeightTests`, which measures the rendered hairline against the contents' top edge rather than the source.
- **A commit button completes a flow; a tap that already took effect has nothing to complete.** Apple is explicit — *avoid using Done buttons for things other than completing the task* — and a Done with no Cancel was never a commit in the first place, since backing out is the whole point of deferring. So the model carries an optional `Commit` whose title the caller names (Done, Confirm, Pay) for flows that genuinely end in one, and every catalog picker leaves it nil: each tap applies immediately and is instantly reversible. NN/g sets the same bar from the other side — reserve a commit step for actions with serious consequences, never for routine ones.
- **A picker tray is a menu, so it closes on selection — every one of them.** Section, theme, appearance and device are each a flat list of mutually exclusive options opened from a control that shows the current value, which is Apple's pop-up button (its `Menu` on iOS): choosing an item closes it and the control reports the new value. One gesture has to mean one thing, and an earlier rule that kept a sheet open when its effect was visible behind it reasoned about visibility while the user reasons about the tap — comparing two themes is real, but a transient sheet is the wrong home for it (Apple puts the picker that most invites comparison, Appearance, on a persistent Settings screen). The cross still closes without choosing, and a `Toggle` inside the tweak sheet does not dismiss, which is consistent: a switch is not a single-select row.
- **A tray is a set of rows, so a whole screen stays a sheet.** Every catalog surface of ours is a tray, and the one presentation that isn't is a presented catalog item — `.sheet(item:)` sized by `detents(for:)` from `PinwheelItem.presentation`, or `.fullScreenCover(item:)`. Converting it would nest a tray inside a tray, since a presented item carries its own chrome and its wrench opens the tweaks tray over it; `presentation` is also consumer API whose only live proof is those items, so dropping `.medium` would leave a public option nothing exercises. The line is the job, not the mechanism: rows get a tray, a screen gets a sheet.
- **The tray is raised from SwiftUI only, and what a UIKit one lacks is content, not a shell.** `PinTrayChassis` is a `UIViewController`, so a `UIPinTray` shell would be thin — but a tray's content vocabulary (`PinTraySection`, `PinTrayChoice`, `PinLabel`) is SwiftUI, so such a shell either takes SwiftUI content, which `pinwheelTray` already gives a consumer writing SwiftUI, or needs a parallel UIKit row vocabulary, which is the second implementation per component we refuse. There is no first real use either — every tray we have is a catalog surface written in SwiftUI — so `Catalog.tray` carries only `.swiftUI` and that is honest rather than a hole. When a UIKit consumer appears, the cheap answer is a `present`-style entry point taking SwiftUI content, built with that consumer's screen in the same change.
- **Open follow-up: the theme control does not show which theme is active.** A pop-up button is a pair — the menu closes *and* the control reports the selection — and the bar does that for section (its title) and appearance (its icon changes) but not theme, whose palette icon looks the same for every brand.
- **The chosen row is outlined, not ticked.** A tinted row alone conveys state in colour, which WCAG 1.4.1 rejects unless the difference clears 3:1, and 1.4.11 names *selected* as a state needing 3:1 against its surroundings — so a soft fill cannot carry the meaning by itself. The border is a shape, which frees the fill to stay soft, and it reads in dark where the fill nearly vanishes. Radios are wrong here for a second reason: a radio is a form control promising a submit, so it advertises a commit button that isn't coming. Reach for a mark-free fill only if it is strong enough to clear 3:1 on its own. The outline is `secondaryText` over a `secondaryBackground` fill, not the brand's `actionText`: measured, the blue border cleared only 3.52:1 in light against the row's surface where the neutral clears 10.94:1, so the calmer choice is also the accessible one. The fill alone reads 1.12:1, which is why it cannot carry the state without the border. Carried by `PinTrayChoice`, the one row every picker uses.
- **A sheet stands as tall as its rows, at every depth, and lets the system paint its own background.** There is no native fit-to-content sheet on iPhone — `presentationSizing(.fitted)` is iPad/macOS only — so `PinwheelSheet` measures its content with `onGeometryChange` and feeds `.presentationDetents([.height(h), .large])`. Three traps, all silent: a `List` cannot be measured (a scroll view takes all the height offered, so it reports the sheet back to itself, hence a `VStack`); an outer `.presentationDetents` on the *sheet call site* overrides the inner one, which is what left a pushed picker at its parent's height with a third of the sheet empty; and a sheet adds its bottom safe-area inset on top of the detent, so the ask discounts it. A *pushed* sheet does re-measure once no call site overrides it — measured, the device list sizes to its own rows inside the tweak sheet. iOS 26 applies Liquid Glass to any sheet declaring a partial-height detent, and an opaque `.background` paints over it — a view-hierarchy dump found the backdrop views (`_UILumaTrackingBackdropView`/`_UIVisualEffectBackdropView`) present under the fill. **We override it deliberately**: the sheets take `primaryBackground`, because a themed surface reads with more contrast against the dimmed catalog than the material does. Reach for the glass by removing that background, not by adding a modifier. Now that the catalog's own surfaces are trays with their own geometry, this governs the one path that is still a UIKit sheet: a presented catalog item, sized by `detents(for:)` from `PinwheelItem.presentation`.
- **A tweak is a command, a switch, or a choice.** `PinwheelTweak.Control` gained `.select(options:selection:)` because four demos were spelling a choice longhand — `PinStateViewDemo` and `PinTableViewDemo` each assigned one mutually-exclusive variable from four independent action tweaks, so nothing could report which state was live. The case ships with those two converted, and its options render as `PickerRow`s **inline in the tweak sheet**, the chosen one outlined. A pushed list was tried first and was wrong: the options were already flat rows, so the only thing missing was the selected state, and a push answered it by charging a second tap and a level of navigation for a component with one tweak. A device is a different axis and keeps its push; a variant is the sheet's own content. It stays non-generic — titles plus an `Int` binding — because `PinwheelTweak` is `Identifiable`/`Equatable` inside a `[PinwheelTweak]` behind a `PreferenceKey` and a result builder, and making it generic infects all four. **The trap it had to pay for:** the sweep addresses a variant by title (`-PinwheelPreviewTweak <title>`, enumerated from the dumped titles), so collapsing four tweaks into one would have silently dropped three captures from every sweep, light and dark. An option list therefore answers to each of its *options* rather than its own title — `previewVariantTitles` and `applyAsPreviewVariant(named:)` — guarded by two named tests. UIKit stays unbridged: `Tweak` has no selection member, and the seam waits for a real use.
- **The wrench is the component's own tweaks, and nothing global.** It opens `Tweaks` — the vocabulary the code already uses (`PinwheelTweak`, `Tweakable`, `chrome.tweaks`) — with the device button in the header's trailing slot, since a simulated device frame is per-presentation rather than a global axis, and "No tweaks" centred when a component declares none. Theme and appearance live only in the index's bottom bar; changing brand with a component open means closing it, which is the accepted cost of one meaning per control. **Superseded:** the axes briefly lived here as rows and the sheet was called `Settings`, which left a per-component control opening a global screen while the same axes sat in the bottom bar — the duplication, not the rows, was the defect.
- **Apple's controls are themed where they are ours, stock where they are the subject.** `UIPinTableViewCell`'s `UISwitch` takes `onTintColor = .actionText`, because a switch inside our component is ours and Apple's green is in no brand's palette. The `Apple Controls` demo keeps its system green and blue on purpose: it exists to capture stock controls as named placeholders for the Figma iOS UI Kit swap, so tinting it would make the capture misrepresent what it stands for.
- **Menus cannot be themed, so a picker is a tray.** Menu items render through UIKit with the system font and tint, so every picker is a `PinTray` of `PinTrayChoice`s instead — themed, and one shape for every axis, at every depth.
- **Colors are trait-reactive for free; fonts are not.** A color token is a `UIColor(dynamicProvider:)` reading `traits[PinwheelThemeTrait.self]`, the same mechanism that gives light/dark, so every existing `.primaryText`-style call site became brand-reactive with no change. `UIFont` has no dynamic-provider counterpart, so a font token resolves once against the traits current at the read — which is why SwiftUI font call sites take the theme explicitly (`PinTextStyle.font(in:)`) rather than reading a static.
- **Label → `PinLabel`** (themed `Text`) + an independent trivial `UIPinLabel`. Both are fed by the same provider tokens; neither hosts the other (a label needs no hosting bridge). `PinLabel` exists because raw `Text(...).font(.body)` resolves to *Apple's* system style — a silent footgun that regressed the demos. `PinLabel.font` takes a themed `PinTextStyle`, not a raw `Font`, making the system-font path unrepresentable.
- **Shared vocabularies are top-level types**, so no component owns what another reuses: `PinTextStyle` (typography, used by `PinLabel` and `PinButton`), `PinState` (content state, promoted out of `PinStateView.State`, used by `PinStateView` and `PinList`), `PinLabel.TextColor` (color roles).
- **Color tokens have a SwiftUI-native shorthand.** A public `extension ShapeStyle where Self == Color` forwards the `UIColor` tokens, so any `ShapeStyle`/`Color` context takes a token the way it takes `.red` — `.background(.primaryBackground)`, `.foregroundStyle(.actionText)`. The `UIColor` extension stays the canonical definition (the shorthand just forwards, and `Color(uiColor:)` preserves the dynamic provider so the theme still resolves); prefer the leading-dot form at call sites. It can't reach `.listRowBackground(_:)` (parameter is a generic `View`, not a `ShapeStyle`), so those stay spelled out.
- **`PinList` is greenfield SwiftUI** (themed `List` + `PinState`, value-based rows) — the counterpart of `UIPinTableView`, *not* a replacement: the UIKit table stays for recycling. Non-loaded states reuse `PinStateView`.


## Figma capture


- **The capture toolchain is split: Swift engine in `Demo/FigmaCapture/`, Figma/JS half in `figma-plugin/`.** `figma-plugin/` (repo root, its own npm package) holds the "Pinwheel Capture Import" plugin (`code.ts` → `code.js`, `manifest.json`, `ui.html`) and `serve.mjs` — the local serve on `:8787` the sweep pushes to and the plugin reads from. It lives at the root, **not** under `Demo/` — that's a file-system-synchronized group and would bundle the JS into the app. Edit `code.ts` and `npm run build`; never hand-edit `code.js`. (The token variable collection is "Pinwheel Tokens".)
- **A Figma-captured surface must render into SwiftUI's own tree — never a UIKit-backed `List`.** Capture reads SwiftUI's DisplayList off an *off-screen* host; a `List` (UIKit-backed — `UICollectionView` on iOS 16+, `UITableView` before) builds its rows lazily in the UIKit layer, which an off-screen host with no viewport never populates. So a `List` screen captures as an empty background shape (the rows are simply not in the DisplayList). Build capturable demos/components as `ScrollView { VStack { ForEach } }` — eager, fully in SwiftUI's tree, so every row renders and captures as editable text/color nodes (Numbers, Typography, Color). `LazyVStack` is pure SwiftUI but still lazy (viewport-gated), so it's not a safe capture bet either.
- **Components capture with zero cooperation — every `Pin*` is byte-for-byte identical to `main`, no capture code, no markers.** The engine derives everything from what the component renders: structure from the DisplayList geometry, names from reflection, token bindings by value-matching the rendered `UIColor`/`CGFloat` against the `PinColorToken`/`PinFloatTokens` registries, and live UIKit controls (including a loading button's `UIActivityIndicatorView`) by cropping the on-screen render. A consumer drops their existing components in and they capture as-is — the contract that lets this scale. (The old marker apparatus — `pinCaptured*` modifiers, `PinCaptureKey`, `PinComponentStyle`, the `pinCapturing` fork — was proven dead and deleted; only `PinCaptureLayout` survives as the engine's layout IR.)
- **A raw `List` — even with `Section`s and rich rows — captures fully, with zero cooperation.** A SwiftUI `List` is a recycled `UICollectionView` whose every row is its own `CellHostingView` DisplayList boundary the root host can't see. `PinSwiftUIListCapture` force-realizes the collection (sizes it to `contentSize`), then per cell gathers the leaves of every hosting view in that cell — shifted into cell coordinates — and builds one row by containment (`PinDisplayListCapture.containmentNode`, which seeds a transparent root spanning the union so a lone leaf still nests). A whole rich row (thumbnail, SALE pill, strikethrough was-price, stepper ±) lives in one `CellHostingView`, so this reassembles it 1:1. Section headers are supplementary views (`elementKindSectionHeader`), captured the same way and ordered by Y. The rows then run through `componentizeRepeatedChildren` like the DisplayList path, so repeated rows share one component. (`ProductListDemo` is a plain `List { Section { ForEach { row } } }` with `onDelete` — 2 headers + 6 rows → a header component + a 6-instance row component.) The earlier per-hosting-view `document(EmptyView())` path collapsed each cell to one text — the fix was to build from the cell's own leaves via containment, no reflection. Lazy stacks/grids (`LazyVStack`/`LazyVGrid`) already capture fully on the on-screen host. **This is why the demo stays a raw `List`, never rewritten to `ScrollView`/`VStack` to appease the capture** — reverse-engineer the real thing so a consumer's existing `List` just works. This also retired `PinList`'s old capture switch: it used to render an eager `ScrollView`/`VStack` under a `pinCapturing` environment because the DisplayList couldn't see `List` rows; now `PinList` is just a themed real `List` (one implementation) and the engine captures it — the `pinCapturing` environment and the `capturableStack` are gone.
- **Repeated-cell componentization keys images by bytes and buckets size to ~16pt.** An image node's signature is its byte content, so identical icons/chevrons group (an instance shares the master's identical image) while per-row photos stay distinct (an instance can't override an image); size buckets to ~16pt so content-driven width jitter doesn't split one template while a real size difference still does.
- **The capture engine is chosen by the item's hosted *world* (`PinwheelItem.isUIKitHosted`), never its display tag.** A `view:`/`viewController:` item walks the real `UIView` tree (`PinUIKitCapture`); a `content:` item reads its SwiftUI DisplayList. Routing on the `.uiKit` display chip instead misfires whenever the two diverge — a `.figma`-tagged UIKit demo (the `UICollectionView` grid in Screens) captured as one flat image because `.figma` isn't `.uiKit`, so it took the DisplayList path over a UIKit-hosted view. `isUIKitHosted` is set at construction (UIKit inits → `true`, SwiftUI → `false`), so the display tag stays a pure presentation axis. (A plain `UICollectionView` then captures with zero cooperation — force-realized cells → rounded token fills + centered editable labels — same as the UIKit table.)
- **The sweep captures from the live *on-screen* host; auto-push captures off-screen.** A UIKit-backed control (`Toggle`/`Slider`/`Picker(.segmented)`/`Stepper`/`DatePicker`, and `ProgressView`) only populates the DisplayList once it has actually rendered on a window — an off-screen `UIHostingController` renders it incompletely and its leaf drops (reflection then falls to the containment path and loses it). So `FigmaCaptureSweepView` hosts the component on-screen (`LiveCaptureHost`) and reads leaves off that real render (`PinDisplayList.leaves(fromHost:)`); `document(_:liveHost:)` is that entry. Auto-push has no on-screen surface, so it keeps the off-screen `document(_:)` path (its controls are best-effort). Build capturable component demos that render eagerly (`ScrollView { VStack }`, not `List`/`LazyVStack`) so every node is present.
- **Dark mode = two sweep rounds in the SIM's appearance, merged — a UIKit control can't be flipped in-app.** A UIKit control only paints in the *simulator's* appearance; neither `preferredColorScheme` nor a window/controller `overrideUserInterfaceStyle` repaints a SwiftUI-hosted control for the `drawHierarchy` crop (proven: window forced dark, control still cropped light). So the sweep runs the whole catalog twice — `simctl ui appearance light`, then `dark` — capturing a single-appearance document each round, and a Python step in `sweep.sh` grafts the dark round's `image`/`fill` onto the light one as `imageDark`/`fillDark`. Everything then adapts: controls, symbols, and untokenized fills via the merge; tokenized colours via the token's own light/dark value. (Round 1 must be *light* so text RGBA-matches the correct token.)
- **Both themes are tokenized via per-theme variables (`color/light/<token>` + `color/dark/<token>`), NOT variable modes.** A Figma variable collection can't hold a second (Dark) mode without a paid plan — `collection.addMode('Dark')` throws `"Limited to 1 modes only"` on free/starter (confirmed via a debug probe). Modes are what give *automatic* light↔dark switching (paid). But *tokenization* (binding to named, editable variables instead of raw hex) needs no modes: `syncTokens` creates two variables per colour token, each with its value in the single mode, and `solid()` binds `color/dark/<token>` for a dark import, `color/light/<token>` for light. Dark colours are editable token references, just not auto-switching. Only an *explicit* token binds — a literal `.custom` colour (the black/white contrast labels in the Color demo) has no token and stays a static paint; value-matching it to a token would bind the wrong one (a white label → primaryBackground) and, post-split, the wrong theme. Flip: on a paid/Education plan, collapse to one `color/<token>` variable with Light+Dark modes for auto-switching. Golden-path researched; the round-trips that got here were only cut short once the probe surfaced `darkModeId: null` — instrument the real Figma failure, don't assume.
- **The capture never forces a synchronous render-server commit — that's what exhausts the sim.** `drawHierarchy(in:afterScreenUpdates: true)` waits for the next screen-update cycle and makes the SimRenderServer allocate a fresh full-window surface it never reclaims; across a batch the server saturates and silently stops compositing heavy controls (they import as empty placeholders — the pixels genuinely aren't rendered). The control has already painted on the live window, so `keyWindowControlCrops` uses `afterScreenUpdates: false` (reads the existing front buffer) inside an `autoreleasepool` that releases the bitmap immediately; the host-layer crop is pooled too. Proven: 30 back-to-back control-screen captures on one boot stay complete. Rebooting (`simctl shutdown && boot`, or a full `simctl erase`) is a last-resort reset only if it ever recurs — it is no longer the fix.
- **The live host sizes to `max(screen, content)` height, not the window.** A screen taller than the device (a long button list) clamped to the window drops its below-the-fold rows from the DisplayList; the reflected tree then outnumbers the rendered leaves, the order-zip fails, and the whole screen falls to the containment path — losing every reflected node (e.g. `PinButton` pills). `LiveCaptureHost` constrains the host to the taller of the screen and the content's `sizeThatFits` height, so tall content renders in full while a short screen stays screen-height (controls paint on-window; a centered empty state still centers). Symptom of the regression: `reflect=N > components=M` and the root imports as `tag=frame`.
- **`PinUIKitCapture` walks the real `UIView` tree for any hosted UIKit component — `UILabel`/`UITextView` → text node (alignment-aware tight rect, plus a fill + radius when the label is a colored bar), `UISwitch`/`UIImageView` → live crop; a `UITableView`/`UICollectionView` force-realizes its cells first.** It's tried ahead of the SwiftUI DisplayList path in the sweep and claims a component only when the walk finds real text — so a **SwiftUI-hosting shell** (`UIPinButton`/`UIPinStateView` via `PinHostView`, which has no `UILabel`s of its own) falls back to the flat-image snapshot rather than a broken partial. That fallback is acceptable: the hosted component (`PinButton`, `PinStateView`) captures *editably* through its own SwiftUI catalog entry, so nothing editable is lost. 8 of 11 UIKit components capture as structured nodes (label, numbers, typography, color, both tables, tweakable, fullscreen); the 3 flat-image ones (button, stateView, viewController) all host SwiftUI. Reaching the hosted SwiftUI *through* the shell (reflect each nested `_UIHostingView`) is possible but low-value while the SwiftUI entries exist.
- **A UIKit `UITableView`/`UICollectionView` captures by force-realizing every cell, then reading the real `UIView` tree — no DisplayList, no markers.** The DisplayList path sees nothing inside a UIKit-backed collection (its cells live in the UIKit layer), and a recycled collection only realizes its visible viewport. But a scroll view's cell-culling window *is* its `bounds`: `PinUIKitListCapture` sizes the scroll view to its full `contentSize` on the live host (demo data is small, so recycling is moot), which realizes every cell at once, then walks each cell — `UILabel.text`/`.font`/`.textColor` → editable text node (color value-matched to a token), `UISwitch`/`UIImageView` → live front-buffer crop (same `afterScreenUpdates: false` + `autoreleasepool` discipline). Wired ahead of the SwiftUI path in the sweep (`PinUIKitListCapture.document(...) ?? PinDisplayListCapture.document(...)`), so a component that isn't a UIKit collection falls through. This is the same zero-cooperation contract as the SwiftUI side — a consumer's existing UIKit table captures as-is. (Confirms the deleted marker apparatus was never needed for UIKit either.)
- **Repeated cells capture as a Figma component + instances — edit the master, the copies follow.** Cells of the same class *and* structure share a `component` key (`\(type(of: cell))#t<textCount>f<fillCount>`, assigned in `realizedRows` only to groups of ≥2); the plugin imports the first as a main component and the rest as instances, overriding just per-instance text/fill (`applyInstanceContent`). A cell carrying a live crop (a `UISwitch`/icon image) is *excluded* — an instance's text/fill override can't reproduce a bitmap, so it stays an independent frame (also why the table's toggle rows don't collapse onto a text-row master). Class is part of the key because Pinwheel's `UIPinTableView` uses one polymorphic cell class for every row, so structure alone would merge unrelated templates. `FigmaNode.component` and the plugin's `masters`/`createInstance` path were dormant plumbing (a marker-apparatus survivor) until the capture began stamping the key. (`CollectionViewGridDemo` shows it: two card templates → two components, four instances each.)
- **The SwiftUI DisplayList path does the same, but keys on a structural signature (no cell class exists).** A post-pass (`componentizeRepeatedChildren`) stamps sibling frames that share a signature — tag, size bucket, layout *axis*, fill/radius tokens, and recursive child shape (text nodes contribute only their style, never content). It deliberately drops inferred `justify`/`align`/`gap`: those wobble with text width across otherwise-identical cards and would falsely split one template (instances inherit the master's layout regardless). Size is bucketed to ~4pt (sub-pixel text heights mustn't split a template) but *is* in the signature, so genuinely different-sized cards don't merge — that's what makes a grouping faithful, since an instance can override only text/fill, not size. The pass only *adds* the `component` field (never restructures), so it can't regress an existing capture. (`CardsDemo` shows it: two SwiftUI card templates → two components, four instances each.)
- **Table-drawn chrome (separators, disclosure chevrons) lives *outside* `contentView`, so reconstruct it from the table's own state.** A `UITableView` draws its separators itself and renders the disclosure indicator as `accessoryType` — neither is in any cell's `contentView`, so the walk misses both (the capture came back with no dividers and no chevrons). `PinUIKitListCapture` rebuilds them: a hairline separator between consecutive rows colored from the table's `separatorColor` (tokenizes, so it adapts in dark), and an SF Symbol `chevron.right` for each cell whose `accessoryType == .disclosureIndicator`. Derived from what the table exposes, not a marker.
- **Capturing a UIKit label: read the tight text rect, not the label frame.** A `UILabel` in a fill-aligned `UIStackView` gets a frame as wide as the widest sibling, so a short string ("subtitle") captured at that width makes Figma justify it across the box ("s u b t i t l e"). Capture `label.sizeThatFits(...)` (the glyph rect) at the label's leading origin so the text node hugs the glyphs.
- **A UIKit collection sits below the safe-area inset; lift the capture to the top.** The table's first cell starts ~62pt down (the safe-area content inset), a gap the SwiftUI capture already trims. `PinUIKitListCapture` shifts the whole list up by the first row's offset so content begins at the top, matching the SwiftUI side.
- **The sweep owns a dedicated simulator, resolved by UDID — never "whichever is booted".** `resolve_udid` finds (or creates) a persistent sim named `Pinwheel Sweep` and ignores every other device, so a stray booted sim can't be built/captured against by accident (the bug that silently shipped stale captures: the sweep grabbed the wrong sim, built there, and the serve never updated). It's created on the newest available iOS runtime + newest iPhone (a capability, not a pinned model, so it survives runner/Xcode bumps), reused across runs to stay warm, and `bootstatus -b` waits for boot. Override the name with `PINWHEEL_SIM`. Modeled on `tienda-ios`'s `bin/screenshot-sweep` (the `elvis/screenshot-harness` "dedicated, pinned simulator" pattern).
- **A stale sweep build silently ships an old capture.** The sweep's incremental `xcodebuild` (derived data at `/tmp/pinwheel-sweep-dd`) sometimes doesn't recompile a changed *package* source, so the app captures with the pre-fix binary and the serve looks unchanged while the fix is real (proven by unit tests). When a capture doesn't reflect a just-made source change, `rm -rf /tmp/pinwheel-sweep-dd` and re-sweep for a clean build before believing the capture over the test.


## Catalog, FAB & settings


- **One pure-SwiftUI catalog, and the tray is its only sheet.** The legacy UIKit-first catalog (`PinwheelTableViewController`, section/split VCs, the item-hosting `PinwheelViewController`/`PinwheelHostingViewController`, `TweakingOptionsTableViewController`, helpers) was removed — public-but-dead (instantiated nowhere; the Demo/README lead with the SwiftUI `PinwheelCatalog`, and `MIGRATION.md` exists to move off it). That removed the second (UIKit) settings sheet; `PinwheelItem.viewController` and the `makeViewController` path went with it. UIKit *components*, the bridges (`PinHostView`, `PinwheelUIKitCompatibility`), and the `PinwheelItem(view:)`/`(viewController:)` initializers that drop UIKit content *into* the SwiftUI catalog all stay.
- **Ids derive from title + tags; there is no manual `id:`.** `PinwheelItem.id`/`PinwheelSection.id` are computed — an item slugs `tags + title` (`Button`+`.uiKit` → `uikit-button`), a section slugs its title. Persistence (selected section/item/device) and deep-links key off these. The contract: title (plus tags, for an item) must be unique within its scope — two same-titled items are disambiguated by tags, which is why the `id:` override and its `explicitID` backing were removed. `PinwheelItem.generatedID(title:tags:)` is the public builder (used to form a deep-link without hardcoding the slug); it's `nonisolated` (pure) despite the package's `.defaultIsolation(MainActor.self)`.
- **Catalog groups by concept, axes are tags.** Sections are concept buckets (`Tokens`/`Components`/`Screens`), not `SwiftUI`-vs-`UIKit` splits; each component's SwiftUI and UIKit takes share a section and are told apart by a `PinTag` chip. `PinTag` is an **open** `RawRepresentable` struct, not a closed enum — the library ships `.swiftUI`/`.uiKit`, and a consumer adds its own axis with a static extension (`DemoCatalog` adds `.figma` for the capture-demo screens in `Screens`), mirroring how `PinwheelComponent` is a consumer-implemented protocol rather than a fixed list. Tags also drive a horizontal filter-pill bar under the section picker (shown only when a section has >1 distinct tag; resets on section change). The row is `.contentShape(Rectangle())` so the whole width taps, and carries `.accessibilityIdentifier(item.id)` so UI tests navigate by stable id, not title (titles now repeat within a section). **SwiftUI is the default and carries no tag** — a chip earns its place by saying a take departs from it, so only the UIKit and Figma items wear one and a SwiftUI row is a bare title. That makes a SwiftUI item's id its title alone (`button`, not `swiftui-button`), a one-time selection reset like `reciclable` → `recyclable`, and it changes when a filter pill appears: a tag counts when filtering by it would leave something out, so a lone `UIKit` pill shows in a section of otherwise untagged items, while a tag every item carries shows none.
- **Typed catalog identifiers: `PinwheelComponent` (library) + a consumer enum in a shared module.** The library ships `PinwheelComponent` (a `RawRepresentable where RawValue == String` refinement) plus generic `PinwheelItem`/`PinwheelSection` inits and a `id(_ tags:)` default — so any consumer declares one `String` enum (`enum Catalog: String, PinwheelComponent { case button = "Button" }`) and gets typed authoring (`PinwheelItem(Catalog.button)`) *and* a typed deep-link id (`Catalog.button.id(.uiKit)`), with no id/slug literal. Leading-dot at the call site (`.button`) isn't possible because the init is generic over the consumer's type — write `Catalog.button`; that's the price of the library not knowing your enum.
- **The consumer enum lives in a module both the app and its UI tests import — this is why `DemoCatalog` exists.** A UI-test target runs in a separate process and can't `@testable import` the app, so the identifier enum can't live in the app target. The demo models the fix a real consumer would use: a small local SwiftPM package (`DemoCatalog/`, `@_exported import Pinwheel`) holding `Catalog`/`CatalogSection`, depended on by both the Demo app and DemoUITests. The launch-arg is still a string at the boundary, but both sides *derive* it from the same enum (`Catalog.stateView.id(.uiKit)`) — one source of truth, not a hand-copied `"uikit-stateview"`. `DemoCatalog` is demo-only and not part of the distributable `Pinwheel` product; the library ships only the protocol.
- **Registry doubles as the preview index.** `PinwheelPreview(id, sections:)` renders any catalog item in isolation; the Demo deep-links to one component via the `-PinwheelPreview <id>` launch arg.
- **One FAB, hosted in a pass-through overlay window.** The floating tweak/close controls are the single UIKit `CornerAnchoringView` (direct-manipulation drag + velocity throw + corner persistence), now used only by the SwiftUI catalog/preview, hosted in a `UIWindow` above the app (`PinwheelFloatingControlsHost`) so they float over sheet presentations and are never clipped to a `.medium`/`.large` detent; the window's `hitTest` surfaces only the FAB buttons, so content below stays interactive.
- **`PinwheelChrome` is the SwiftUI↔window seam** — an `@Observable` the catalog/preview owns and the window observes (tweaks, presented-state, settings visibility, selected device, close action). State lives here, not in playground `@State`, so the sheet, the playground resize, and the pill share one source of truth and survive re-renders.
- **Hosted items are built once** (`PinwheelHostedItem`) so playground re-renders (e.g. opening settings) don't recreate the hosted view or reset its emitted tweak preference.
- **Settings: tweaks and devices are separate screens.** A `NavigationStack` — an "Options" root (tweaks only) with a trailing device-icon button that pushes a "Device" list (oversized devices dimmed, the selected one checked).
- **The simulated device shows as a floating pill** (`PinwheelDevicePill`) — a top-anchored SwiftUI `.overlay` *on the playground itself* (not the FAB's overlay window), persisting after the settings sheet is dismissed. It's an indicator — only a reset `×` is interactive (returns to the real device). A simulated (smaller) device is letterboxed against `primaryText` (inverse-of-surface) so the frame is visible in light and dark. The pill rides the playground rather than the window so its shrink+fade is a plain SwiftUI `.transition` — hosting it in the window (`UIHostingController` + `.intrinsicContentSize`, top-pinned) collapsed its frame on the way out instead of scaling in place. Trade-off: behind the `.large` settings detent it's covered (fine — the device list shows the active checkmark); at `.medium` it still peeks above. The FAB still fades independently (the FAB hides while settings is open; the pill doesn't).
- **The device-frame resize snaps, never implicitly animated.** An `.animation(_:value: selectedDeviceIndex)` on the playground (to animate the resize/letterbox crossfade) overflowed SwiftUI's layout engine into a stack-overflow crash on *every* device pick — it animates the whole subtree, including the hosted item and the tweak-preference plumbing. The crash reproduced with and without the old `GeometryReader`/`.position` letterboxing, so the animation modifier itself is the cause, not the geometry math. The playground now centers a fixed-size frame inside an infinity frame (no `GeometryReader`/`.position`) and the resize snaps. Guarded by `TweakableUITests.testSelectingSimulatedDeviceDoesNotCrash`.
- **iPad device presets dropped** — the Device preset list was simplified.

## Decisions

Durable design decisions and why they were made.

## Component surface (when a `Pin*` exists)

- Add a SwiftUI `Pin*` (with a thin `UIPin*` shell) **only when** SwiftUI lacks a first-class primitive, so styling would be hand-rolled anyway (`PinButton` — pill, variants, loading, symbol, haptics), **or** there's real imperative / UIKit-hosting value to bridge (`PinStateView` as a state machine a UIKit table can drive). If SwiftUI's primitive + `PinwheelTheme` already covers it and nothing needs to host it in UIKit, don't wrap it.
- **Exception — theme footguns get a wrapper anyway.** `Label → PinLabel` because raw `Text(...).font(.body)` silently resolves to Apple's system style (see Theme below). The test is "does the raw primitive bypass the theme?", not just "does a primitive exist?".
- **Switch → `Toggle`** (no standalone `PinSwitch`; the only switch lives inside the `UIPinTableView` family). **Tokens (Font/Color/Spacing)** are *tokens*, never components, in either world.
- **`Stepper → PinStepper`** (a `−`/value/`+` pill). SwiftUI's `Stepper` renders a system `±` control that bypasses the theme and can't be the pill shape a design system wants — a theme footgun, same test as `PinLabel`. `PinStepper(value:)` + `.onDecrement/.onIncrement` modifiers; bordered capsule, SF-Symbol `±` (mirrors `PinButton`'s `systemImage:`), themed value. Migrated from tienda-ios's Kolibri `KStepper`. No `UIPinStepper` — no UIKit-hosting need yet.

## Bridging

- **The UIKit twin of a `Pin*` component is `UIPin*`, not `UIKitPin*`.** Mirrors Apple's own prefix — it's `UILabel`, never `UIKitLabel` — and next to the SwiftUI `PinLabel` reads as "the UIKit one" to any iOS dev; the `Pin` brand token right after `UI` keeps it from colliding with Apple's `UI*` namespace. The spelled-out `UIKit` survives only as a *descriptive qualifier*, never a component prefix: `PinUIKitCapture`/`PinUIKitListCapture` (which capture path), `PinwheelUIKit*` (the hosting bridge), `isUIKitHosted` (what an item hosts). A raw-control demo with no `Pin` token to disambiguate keeps a non-`UI` name (`CollectionViewGridDemo`, not `UICollectionViewDemo`) so it can't be read as an Apple type.
- **One implementation per bridgeable component.** A `Pin*` SwiftUI source plus a thin `UIPin*` shell that hosts it (via `PinHostView`), never two parallel reimplementations. Theming, light/dark, and Dynamic Type cross the bridge for free because both worlds read the same theme providers.
- **Bridged: Button, StateView.** `UIPinButton` / `UIPinStateView` host the SwiftUI implementation. Trade-off: one `UIHostingController` per instance — acceptable for these leaf/overlay components; revisit for dense reused contexts (e.g. table cells).
- **State overlay centers via `centerY` in the shell**, not by filling. `PinHostView` sizes to intrinsic content, so a fill approach collapses to the top; centering lives in the shell, mirroring the old UIKit layout.
- **UIKit `view:` catalog items host at full bounds** via `PinwheelUIKitContainerViewController` (a `UIViewControllerRepresentable` handed the full proposed size), not a bare `UIViewRepresentable` (which sized to the fitting size and collapsed edge-pinned / table-backed examples to the top-left).
- **UIKit `Tweakable` options bridge into the playground.** A hosted `view:`/`viewController:` item's UIKit `Tweak`s map to `PinwheelTweak`s (`TextTweak` → action, `BoolTweak` → toggle, `SelectTweak` → choice) and surface in the tweaks tray. A `SelectTweak` reads its chosen option through a closure rather than storing one, because the hosted view stays the only owner of the choice — and the tray reads the option in force from the binding, since a UIKit host bridges its tweaks once and a build-time snapshot would freeze at whatever was chosen when the playground appeared. `PinwheelTweak.chosenOptionWhenBuilt` keeps that snapshot for equality alone, which is what makes the preference propagate. Guarded by `testABridgedChoiceReportsTheOptionInForceRatherThanTheOneItWasBuiltWith`.
- **A hosted UIKit `view:` is built once and reused.** `makeSwiftUIView` is called on every playground re-render; it must hand back the *same* `ViewType` instance each time. The bridged tweak closures capture that instance and the hosting controller displays it — a fresh instance per render makes the tweaks mutate an off-screen copy, so UIKit tweaks silently do nothing under nested presentation.
- **`viewController:` items follow the same rule** — both `PinwheelItem(_:viewController:)` inits build the controller once and bridge `Tweakable` (reading its `tweaks` into the playground), mirroring `view:`. A `UIViewController` that conforms to `Tweakable` gets its tweaks in the settings sheet, and they drive the live (on-screen) instance — not an off-screen copy.

## Intentional UIKit surface (kept on purpose)

These stay UIKit because no SwiftUI primitive matches their ergonomics/perf:

- **`UIPinView` base** — `setup()` lifecycle, open subclassing.
- **`UIPinFullscreenView`** — a base class for keyboard-aware full-screen screens (forms/editors): bottom-anchored content rides above the keyboard, plus a synthesized `viewDidFirstAppear()` hook. Kept UIKit and has **no SwiftUI demo on purpose** — SwiftUI gives keyboard avoidance and `onAppear` for free, so there's nothing to build; a SwiftUI "FullscreenView" example would only imply a component that shouldn't exist.
- **`UIPinTableView` family** — cell recycling, dataSource/delegate contract, `UISwitch` items, A–Z section indexer; no `List` equivalent with comparable perf.

## Project layout

- **Sources organized by domain, not access level.** `API/` (public surface), `Tokens/` (tokens, both worlds, incl. SwiftUI `PinwheelTheme`), `Components/SwiftUI` + `Components/UIKit` (split by world; `TableView/` under UIKit), `Catalog/` (the one, pure-SwiftUI catalog + FAB + device/state), `Bridge/` (SwiftUI↔UIKit), `Extensions/`.
- **Demo mirrors the split** — `Demo/Demos/SwiftUI` + `Demo/Demos/UIKit`. Every catalog demo screen lives here (the Figma-capture demos included); `Demo/FigmaCapture/` holds only the capture *engine* (host/IR, scroll-stitch, the sweep harness), never a browsable screen.
- **Both targets are file-system-synchronized groups**, so the folder layout *is* the project structure — moving/adding files needs no `project.pbxproj` edits. (The Demo app target's synced group excludes `Info.plist` so it isn't double-copied as a resource.)
- **Distribution nesting left as-is (deliberate):** the package lives in `Pinwheel/` (the Demo references it locally); a second root `Package.swift` re-exposes it for external `.package(url:)` consumers. Awkward (`Pinwheel/Sources/Pinwheel/`, two manifests) but changing it touches external import paths — not worth it now.

## Open follow-ups

- **Bridged-component cost** — one `UIHostingController` per `UIPinButton`/`UIPinStateView`; revisit only if used in dense reused contexts (table cells). A watch-item, not actionable now.

(The "Recyclable" section was renamed from the misspelled "Reciclable"; its persisted id changed `reciclable` → `recyclable`, a one-time selection reset.)

## The device-picker UI test, and why it is gone

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

## Waiting for a keyboard that is not coming

A tray that will raise a keyboard holds still until it moves, so a shrinking card does not drop to the
floor and climb back. That hold is a bet, and with a hardware keyboard attached it never settles: the
field takes focus and nothing rises, so the tray sat at its content's height — 245 of a possible 834 —
for as long as it was open.

The first answer was a stopwatch on the bet, `trayKeyboardGrace`, which is a guess about the world
dressed as a timeout, and behaviour behind a delay. `GSEventIsHardwareKeyboardAttached` in
GraphicsServices answers the question outright, so `PinTrayKeyboardPresence` asks it and `edits` means
"will raise a keyboard" rather than "has focus". Private, looked up by name, absent means no hardware
keyboard — the same answer the simulator gives with one disconnected.

The other half is that a filling tray never needed to wait at all: it is sized by the room, so its top is
the same before and after the keyboard arrives and there is no dip available to it. With both, nothing in
the tray waits on a clock, and the tear-down that used to be a timer beside the exit animation is that
animation's own completion.

## Asking whether a keyboard will appear, and failing twice

A tray sized by what it holds must stand still when it is about to raise a keyboard, or it shrinks to the
floor and climbs back. The hold needs to know a keyboard is actually coming, and two private answers were
tried against a simulator where the software keyboard demonstrably appears:

- `GSEventIsHardwareKeyboardAttached()` returned **true**, and the software keyboard appeared anyway.
  Attached and shown are independent — a hardware keyboard can be connected with the software one toggled
  on over it.
- `+[UIKeyboard isInHardwareKeyboardMode]`, which is what UIKit itself consults and which *should* mean
  "attached and the software keyboard suppressed", also returned **true** while a 345pt keyboard was on
  screen and `keyboardWillShow` reported its top at 567.

Both answers were recorded beside the keyboard that contradicted them. Believing either put the card on
the floor with the keyboard covering its own search field.

Then the runtime was dumped rather than read about: every BOOL property on `UIKeyboardImpl` — forty of
them — plus both class answers and the text-effects window, captured twice, at focus before any keyboard
and again when `keyboardWillShow` fired. **Every value was identical between the two.** Nothing the
runtime exposes moves when a keyboard appears, so there is nothing to predict with.

The dump also explains both failures: `isInHardwareKeyboardMode` does not mean "no keyboard will appear",
it means a hardware keyboard is in use — and the software keyboard can be shown alongside one, which is
exactly this simulator. Read as mutually exclusive it is simply the wrong flag.

What does change is the keyboard's geometry, which `keyboardLayoutGuide` already reports, publicly, and
which the tray is already laid out by.

There is no prediction here worth having, so none is made: `edits` means focus, and the hold is guarded
by the thing that actually removes the need for it — a filling tray is sized by the room, so its top does
not move when the keyboard arrives and it never has to wait. Every tray in the app fills. If one that
does not ever needs the hold, the signal to resolve it should be an event that has already proved
reliable — `keyboardWillShow`, or the guide moving — never a timeout, and never one of these two flags.

## Who a downward drag belongs to

Dragging down from the top of the results, the list rubber-banded over nothing, and then snapped back to
rest the moment the finger reached the bottom of the card and the keyboard began to go. Two things
fighting: the list's own bounce, and the card's dismissal.

There is nothing above the first result, so a downward drag there has nothing to reveal — it belongs to
the card. `PinTrayMachine.cardTakesTheDrag` is the whole rule and is pure: the card takes it when the
list is at its top and the finger is moving down, and once it has a gesture it keeps it to the end,
because a drag that changed hands half way would stop dead under the finger.

The chassis makes that work by watching *alongside* the list rather than instead of it — the card's pan
recogniser returns true from `shouldRecognizeSimultaneouslyWith`, so neither wins the gesture outright and
ownership is decided per movement. While the card has it the list is pinned to its top, or it
rubber-bands underneath and snaps back exactly as before.

The rejected alternative was letting the list bounce and animating it back at the handover, which is two
motions where there should be one.


## A hosting controller that never resizes after its content is swapped

`PinTrayBodyView` shows a SwiftUI list through a `UIHostingController` inside a scroll view. Building it
that way works, and swapping its content afterwards does not: the hosting view keeps the height the *old*
content had, so a 60-row list laid out 20 points tall. The scroll view then had nothing to scroll and
nothing to be pulled past, which is why pull-to-dismiss recorded zero frames — and, in a UI test, why every
row answered `Not hittable` while sitting in the accessibility tree at full strength.

The fix is one line, `hosting.sizingOptions = .intrinsicContentSize`, which is what makes the controller
report what SwiftUI drew as its view's own size on every subsequent pass.

What cost the time was the observable, not the fix. Three plausible assertions were green with the bug in
place: the scroll's content height *at build time*, the same height under Auto Layout in a window, and the
height after a first layout at zero width. Measuring also stayed correct throughout — `contentHeight(fitting:)`
asks SwiftUI with `sizeThatFits` and never consults the hosting view — so the tray sized itself right while
holding rows nobody could touch. Only `show(_:)` *after* the body is standing reproduces it, because only
then is there a previous size to keep. `testRowsShownAfterAttachAreLaidOutAsTallAsTheyMeasure` goes red at
20.3 against 1220.

The general shape: when a hostless test stays green against a bug the app plainly has, the configuration is
wrong rather than the rung. Reach for the app to confirm the bug is still real — the `Not hittable` failure
is what proved the attribution — then keep narrowing the test until it reproduces, and throw away the
assertions that were never red.

*— Elvis, 2026-08-16*

## Containment was the cause behind most of the tray's bugs

The tray was built with SwiftUI holding the pieces and UIKit supplying the card around them. Nearly every
hard bug traced back to that one choice, and each was fixed locally until the list of local fixes became
the argument:

- Gestures fought across the seam. The card's pan and the list's own scrolling both wanted a downward
  drag, and neither could see the other, so ownership had to be arbitrated by a rule written twice.
- Children were findable only by walking somebody else's tree. Reaching the scroll view inside a hosted
  list meant a recursive `subviews` search for `UIScrollView`, which is a search that silently returns
  nothing the day SwiftUI changes what it builds.
- Content laid out against itself rather than against the card. An arriving tray measured its own fitting
  height and drew a search field at the middle of a card twice that tall, which was patched with
  `max(fittedHeight, geometry.height)` — a patch that only ever hid a structural mistake.
- A representable with no scene rendered nothing, so anything presented was unreachable from a test.

Moving containment to UIKit deleted all four rather than fixing them. The tray holds a title bar, a body
and an accessory as plain `UIView`s it constrains itself; SwiftUI supplies only leaves — a row, a title, a
field — hosted by `PinTrayLeafView`. The body owns its own scroll view outright, so
there is nothing to search for, the pan and the scroll are siblings under one owner, and every child is
laid out against the card because the card is what constrains it.

The rule that came out of it: SwiftUI is a leaf technology here. Anything that holds, lays out, scrolls
or routes a gesture is a `UIView` we own.

## A pinned offset destroys the quantity you are deriving from it

Pull-to-dismiss moved the card nine points over a four-hundred-point drag. The body was doing two things
in `scrollViewDidScroll`: reporting how far the offset had gone past the top, and then pinning the offset
back to the top so the list would not rubber-band. The pin is right; reporting after it is not. Each frame
measured only the slice travelled since the previous pin, which is a frame's worth of movement rather than
the gesture's, so the card followed a few points and stopped.

The report has to be a running total the gesture owns — `pulled` accumulates every slice, resets on
`scrollViewWillBeginDragging`, and what the tray hears is "the finger has come 417 points down", never
"the offset moved 9 just now".

The general shape: whenever a value is both *read from* and *written to* the same property in one pass,
the read stops being cumulative and nobody notices, because the number is still plausible. The test names
the fact directly — `testAPullReportsHowFarTheFingerHasComeNotTheLastFrame` pushes three equal slices and
demands their sum, red at 10 against 30.

## A scroll view that is always on, and undone

The first tray moved under a finger that had nothing to scroll. The body was scrollable at all times and
the delegate pinned the offset back whenever a pull went past the top — which cancels the *movement* and
leaves the *state* wrong, so the fix looked right on screen and was wrong everywhere a gesture asked the
scroll view whether it scrolls.

Turning it off properly took a second change nobody would predict from the first. The card's pan refused
every touch inside a `UIScrollView`, on the reasoning that a touch in the body belongs to the body — true
only while the body has somewhere to go. With scrolling off, the body stopped reporting pulls and the pan
still would not take the touch, so a downward drag on a fitting tray belonged to nobody and the tray
could not be dragged away at all. The pan now refuses only a scroll view that *can* scroll.

Two smaller traps came with it. Asking `contentSize` whether the content overflows answers stale during
layout, because the body is asked during the same pass that sizes the scroll view's content — ask what the
rows measure against the room there is instead, which has no ordering to get wrong. And the card was built
from the rows plus the body's *bottom* inset while the body also keeps a top one, so every tray sized to
fit its content was permanently scrollable by exactly that inset: 16 points of travel that read as a bug
in the bounce rather than in the measurement. The body reports what it needs now, insets included, and the
chassis stops adding either of them itself.

## The rubber band is Apple's, and calling Apple's would buy nothing

A tray resists a pull that has nowhere to go. A scroll view gives that for free and gives none of it
here — what has to move is the card rather than the list, and a tray whose rows already fit has no
scrolling to bounce.

UIKit does have the curve: dumping `UIScrollView` turns up
`_rubberBandOffsetForOffset:maxOffset:minOffset:range:outside:` and `_currentRubberBandCoefficient`,
among two dozen other rubber-band and bounce selectors. Called through its implementation pointer, the
coefficient reads 0.55 and the offset matches `(x·d·c) / (d + c·x)` to the penny at 10, 40, 100, 200, 400
and 4000 points of pull.

So the published formula is not an approximation of Apple's, it *is* Apple's, and the private call buys
nothing while putting a private selector into every app that links this library. Worth knowing which way
that argument ran: the reason to skip a private API here is that it was measured to be redundant, not
that it was assumed to be risky.

The tray passes its own `d` — a small allowance rather than the view's dimension, which is what Apple
passes — so however hard it is pulled the card stops short of the strip above it that dismisses it.

## Why behaviour is a value, and which parts of that are ours

The argument is combinatorial rather than aesthetic. Model a surface with independent booleans and each
new one multiplies the states: valid and enabled is four, add dragging and it is eight, and the ones that
are nonsense — loading while disabled while pressed — are as expressible as the ones that are not. Naming
the states instead is what makes the nonsense unrepresentable, and it is why Harel's statecharts exist.
The literature's own framing is worth keeping: a statechart is often *simpler* than the implicit booleans
it replaces, which are merely *easier*.

Three things showed up in the tray that made the value pay for itself, and they are what to look for
elsewhere:

- **The states multiplied.** Leaving, arriving, editing, dragging, caught, and a keyboard that is opening,
  open, closing or closed. As flags that is a space nobody can enumerate; as `Phase` and `Keyboard` it is
  a handful of named values with the illegal combinations absent by construction.
- **Something outside owned part of the timing.** The keyboard cannot be commanded, so *which animation
  carries a change* had to become a value the machine holds. Every attempt to express that as a flag on a
  view produced the same bug twice — two animations over one property.
- **What had to be true was true of a sequence.** `testTheTopNeverReversesOnTheWayToTheKeyboard` caught
  `[263, 448, 129, 129]` in a machine whose every per-step test passed. A step-at-a-time assertion would
  have shipped it.

Provenance, since the three are not equally borrowed. The first and third are established: state
explosion is the standard argument for statecharts, and journey-level assertions are the ordinary payoff
of a pure value. The second — that *which animation owns a change* is itself state — is ours. It was not
found stated anywhere; it came out of the motion tape on this branch, where the pill washing to 0.75, the
button drawn at 1.10, and a leaving tray standing back up were all facts with no home. It is in the rules
on that evidence, and it is the clause to challenge first if it ever stops earning its place.

One deliberate divergence. General advice allows "a simpler alternative is adequate" as a reason to skip
the value, and that is sound written for everyone. It is wrong here, because the two mistakes do not cost
the same: building the value early costs a little ceremony, and leaving it costs a bug that only a video
can show you. So the rule carries no threshold to argue with.

The rule that came out of it: behaviour is a value with no views in it, counted in states rather than
screens.

## Every part is a coordinator or a value, and the name says which

The tray began as one `UIView` called `PinTrayOverlay` that was, at once, the coordinator, the renderer,
the assembler, the measurer, the gesture reader, the body's delegate and the notification observer. It
reached 616 lines that way, and the reason it could is that *overlay* names a position rather than a job:
a name like that never objects to what you put in it.

Audited against "each part is a coordinator, or a value that only decides", five decisions turned out to
be living in the views that drew them — the backdrop's opacity, what counts as a resize, the clearance
above an accessory, which of a tray's two bottoms stands, and whether a move zooms. Each moved to the
value that owns it, and each became a test on the way.

What the split found, in the order it was found:

- **A tray's views are one picture, not three.** Faded separately, an accessory standing over a row lets
  the row through it. Measured on a white ground half way through a fade, that pixel reads 183 where one
  picture reads 247 — the row fades to grey first and then shows through, where a group covers it at full
  opacity and the finished picture fades once. Hence `PinTrayContentsView`.
- **A button that ends a flow outlives the tray that declared it.** It belongs to the card, which is what
  lets "the same button holds still" be a question about two trays rather than a comparison of two
  frames — an exact float equality standing in for identity.
- **The drag had two owners.** The body kept a running total of a pull while the machine kept another,
  seeded from it at the start of every gesture, and the two were different quantities: one raw finger
  travel, one rubber-banded. The body now reports the slice each frame gives it and holds nothing.
- **A lazy view touched during layout is a crash.** `layoutSubviews` runs while the tray is still being
  built, and it reaches for the card; as a `lazy var` that re-enters its own initialiser, which Swift
  does not survive — `signal segv` on every chassis test. It is a stored property built before the tray
  joins any hierarchy, joining its parent through `attach(to:)` afterwards, because a stored property
  cannot be handed `self`.

Two of those were found by measuring rather than reading, and one measurement was the wrong instrument
first: the compositing question was filmed for three rounds, chasing a moving crop, before being answered
exactly by rendering two views and reading one pixel. Compositing is deterministic; film is for motion.

The rule that came out of it: behaviour is a value with no views in it, and every part is named after
what it does.

## A coordinator composes, and composing is not a second job

Auditing the tray against "each part is a coordinator or a value that only decides" found five decisions
living in views and two jobs the chassis had no business doing — drawing the card, reading its gestures.
Moving those out was right. Then the same audit called two more things violations, and they were not:
that the chassis builds a tray's content from its description, and that it asks that content how tall it
measures.

The attempt to move them onto the card failed, and the failure is the argument. A card's job is motion
and position: it stands where a geometry says and travels there on a timeline. Made to also hold content,
constrain it to itself and derive a clearance from what an accessory measures, it had two jobs — and it
objected in the only place it could, by adding constraints mid-construction and leaving the layout
unsettled. The card came out one point tall with a correct height constraint at priority 750 and no
conflict logged, because an optional constraint that cannot be met is dropped in silence.

The line is **deciding versus composing**, not how much code sits in one file:

- Deciding what a value should hold — an opacity, a threshold, a clearance, a zoom — belongs to the value.
- Drawing and reading gestures belong to the view that is drawn and touched.
- **Composing children and asking them their size is what a coordinator is for.** A coordinator that
  composes nothing is a pass-through, not a coordinator.

Line count was the misleading signal. A 390-line coordinator that assembles six parts and translates a
machine's reactions to them is not carrying extra roles; it is doing its one job at the size that job is.

Three theories were offered for the one-point card before the design error was seen — a placeholder
constraint, a missing conflict, an ordering fault — and the diagnostic that ruled each out
(`constraintsAffectingLayout(for:)`) was available from the first round. When a refactor fights back,
weigh that the refactor is wrong before instrumenting harder.

## Where the tray's borrowed numbers come from

Nothing in the source says whose these are, so it is written here once.

- `trayRubberBanding` = **0.55**, `trayDecelerationRate` = **0.99**, `trayThrowSpeed` = **250**. All three
  are UIKit's own, read at runtime off the `_UIHyperInteractor` ivars its sheets hand a drag to —
  `__rubberBandCoefficient`, `__decelerationRate` (factor 99) and `__minimumSpeed`. The rate is also
  `UIScrollView`'s `.fast`.
- The rubber-band curve is Apple's exactly: `(x·d·c) / (d + c·x)`, checked against
  `-[UIScrollView _rubberBandOffsetForOffset:maxOffset:minOffset:range:outside:]` and equal to the penny
  at every pull. It diverges in `d` alone — Apple passes the view's own dimension, a tray passes
  `trayLift`, which is what keeps the strip above the card reachable however hard it is pulled.
- `trayResizeDuration` = 0.30 and `trayResizeBounce` = 0.10 come off the reference capture, not taste.

## The keyboard runs out of process

Its notifications are posted asynchronously, so anything driven off them is racing its animation — the
tray would always be a frame behind, or fighting. A constraint to `keyboardLayoutGuide` is carried *by*
that animation instead, which is why the card's bottom is pinned to the guide and nothing listens for a
frame. What the notifications are still read for is the duration and curve, which the keyboard announces
before it moves, so a tray leaving beside it can borrow the same clock.
