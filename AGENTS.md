# Agent Guidelines

How we work in Pinwheel. Portable iOS conventions live one level up (`~/code/<org>/ios/AGENTS.md`) and are
inherited, so they are not repeated here. **Why** any of this is the way it is — the measurements, the
traps, the bugs behind each rule — is in `LEARNINGS.md`. Read the section covering whatever you are about
to change, add to it as you learn, and keep *this* file to what a session needs nine times in ten.

## Working rules

How a session proceeds.

- **Measure and reproduce before fixing.** A cause is something a run showed you, not something the code
  suggests. Guessing costs a build and a launch per round, and a wrong guess looks exactly like a right
  one that changed nothing.
- **When a refactor fights back, suspect the refactor.** Code that resists being moved is usually saying
  the move is wrong. Instrumenting harder finds the mechanism and misses the mistake — a card made to
  hold content as well as move it came out one point tall, and three rounds went into the constraints
  before the second job was the answer.
- **Ask the app, never an image: a layout fact is a test, not a look.** Screenshots are for external
  references. Pixel-scanning this app has produced contradictory numbers, numbers taken off the home
  screen, and wrong point scales. Every question has an instrument below — reach for it before writing
  one.
- **Verify before claiming done**, and report what you actually observed, failures included.
- **Hand a build over by name, and let the app confirm it.** Shaking shows `build HHmm`, read from the
  running binary's own timestamp, and the recorder's first line carries the same — so open a handover
  with the label and the person holding the phone can check rather than trust. Anything written *beside*
  the binary can describe a different one, which is the staleness it exists to catch.
- **A warning only re-emits on a build that recompiles.** An incremental build skips unchanged files, so a
  clean count comes from a fresh `-derivedDataPath` and nothing less. Five checks in a row read zero off a
  build that compiled nothing.
- **If something should be off, turn it off — don't leave it on and undo what it does.** Undoing hides
  the effect from you, not from the code that reads the flag. And whatever it used to handle is now
  handled by nobody, so say who handles it instead.
- **Adding or moving a file needs no `project.pbxproj` edit** — both targets are file-system-synchronized
  groups, so the folder layout *is* the project structure and a new folder is a real decision.

## What a component owes at runtime

- **A container owns the space around and between its children; a child owns only what is inside it.**
  Both axes, and a constraint is space — so a child holds none that mentions its parent, and publishes a
  measurement only where it owns the number: `intrinsicContentSize` for a view sized by its own content,
  and nothing at all for one whose size a value above it decides. Only the thing that can see both sides
  of a gap can balance it, so the gap between two rows
  belongs to whatever holds them — a section for its items, the tray for its sections — and how far they
  stand off an edge belongs there too. A child that pads its own outside makes every gap the sum of two
  decisions nobody took together.
- **A gesture and the animation that follows it are one motion.** It leaves at the speed the finger let
  go at, it stays interruptible until it settles, and what decides where it ends up is where it would
  come to rest if left alone — never how fast it happened to be moving when it was released.
- **A scroll view scrolls only when its content outgrows its room.**
- **A view measures nothing until it has joined its parent.** A controller's `viewDidLoad` runs the
  moment `.view` is first touched, which is before the caller can add it — so anything needing a room
  waits for `didMove(toParent:)`. Measured detached, a tray built itself 89 points wide and none tall,
  and every correction after that landed somewhere wrong.
- **A value the platform owns is read, never copied.** Read it and the layout is right on hardware and
  OS versions you will never see. Where there is nothing to read, reimplement only what holds still — a
  corner's curve is the same shape on every device, its radius is not.

## Built to be tested

An experience is testable when the facts it rests on live somewhere a test can reach without a screen.
These put them there; the section below says where the test then goes.

- **One place decides and one place draws: behaviour is a value with no views in it, and a view draws what
  that value decided.** Count states, not screens — a control that is valid or not and enabled or not
  already has four — and every rule the value holds is then a test, sequences included. Almost every bug
  here has been the same shape: a second copy of the state, or a second path that animates. Delete the
  copy rather than syncing it.
- **Nothing stands in for a state — no optional, no default, no two-phase setup.** Where `nil` means the
  value lives in another state, make that state a case and read it by matching, so it can only be read
  where it exists; where nothing can supply a value, throw. Dependencies arrive through `init`: a thing
  that cannot exist without a container, a clock and something to show takes all three at birth, and
  every protocol ships a real implementation and a stub so the seam is usable from a test the day it is
  made. A fallback is either the answer or a lie standing in for a state — a height quietly keeping what
  was there before drew a 200-point tray at 794. A placeholder you need because a value cannot be built
  until after `super.init` is the type telling you the value belongs to whatever already exists by then,
  which is the parent — not a licence to write a setup method that fills it in later.
- **A parent composes its children and asks them what they measure; that is its one job, not a second
  one.** Nothing reaches more than one level up or down — downward is direct, upward is a closure or a
  protocol — and each child holds one job and is pure where it can be: the tray's geometry and its
  machine are pure values, and the chassis that draws them owns nothing else. What belongs elsewhere is
  deciding and drawing. Size is not the signal — a parent that composes nothing is a pass-through, and one
  that assembles six parts is doing its job at the size that job is.
- **A child answers to its own delegate and reports upward in its own words.** The body is its scroll
  view's delegate; what it tells the tray is "pulled down by 40", never `scrollViewDidScroll`. A parent
  adopting its child's protocol drags the child's vocabulary a level up where it does not belong.
- **Containment is a UIKit job.** SwiftUI supplies leaves — a row, a title, a field. Anything that holds,
  lays out, scrolls or routes a gesture is a `UIView` we own, which makes it an ordinary object with an
  ordinary frame that a test reads directly, with nothing inferred from a picture. Asking SwiftUI to
  contain is what makes gestures fight across the seam, representables vanish without a scene, and
  children findable only by walking a tree somebody else owns.
- **Where the framework owns the mechanism, move the seam rather than the mechanism.** Auto Layout, the
  keyboard and the render server cannot be injected, and a fake of one would prove nothing — they are the
  implementation, not a dependency. So the boundary goes above them, a pure value deciding the number
  where every rule is a test, and below them, the frame that came out. What sits between is left holding
  no logic worth testing.
- **No behaviour behind a delay.** A timer is a guess about the world. If something must happen when a
  motion ends, use the animation's completion; if it depends on what the world is doing, ask the world —
  a private API answering outright beats a stopwatch estimating.

## Testing

Write the test at the lowest rung that can hold the fact. Moving up needs a reason, and "it was easier"
is not one.

| Target | Holds | Runs |
|---|---|---|
| **`PinwheelTests`** | the library's own behaviour — logic, geometry, tokens, rendering, the capture engine. **The default home.** | hostless SwiftPM |
| **`DemoTests`** | facts needing a live app: anything **presented**, anything needing a real scene or a real keyboard, and Demo-target code the package cannot see | **hosted by `Demo.app`** |
| **`DemoUITests`** | throwaway probes only, **empty at rest** | XCUITest |

- **A bug gets a failing test first, and the test has teeth: it fails against the un-fixed code, for the
  right reason.** Red, run it, then fix — never editing source and test in the same step. Commit the fix
  before reverting to prove the red, or the revert silently eats it, and when a fix ships without a red
  first say so plainly. Only bugs earn a test this way; everywhere else prefer making the mistake
  unrepresentable over asserting it is absent.
- **A fact that needs an app is not an untestable fact.** `DemoTests` is hosted and ships a harness,
  `HostedView`: `window(showing:)` flips `_AXSSetAutomationEnabled` so SwiftUI fills its accessibility
  tree and labels, frames and `accessibilityActivate()` become readable; `presentation(in:)` waits for a
  presented view to join the window; `settledPresentation(in:)` waits for a detent to stop moving. A
  number the framework *produces* rather than takes — an intrinsic size, where a system guide has moved to
  — has no pure value above it to test, so it is read here or nowhere.
- **A UI test does not land, and its one exception costs two things.** Driving the app to watch a change
  work is an instrument: red while the fix is absent, deleted in the change that fixes what it found,
  leaving the unit test for what it localised. A workaround held against SwiftUI or UIKit that nothing
  lower can reach may keep a permanent one — but only with teeth *and* a place in the merge gate, since a
  guard outside the gate is one nobody runs and it rots without telling you. Coverage is never a reason to
  keep one.
- **Drive a layout with constraints; assert the frame.** A frame written on a hosted view hands it a
  height it never had to work out, so the test stops measuring what it claims to — and a constraint read
  back asserts only that your own setter ran. That reads green when the constraint is inactive, when a
  competing one wins, and when an optional one is dropped silently with no conflict log while the view
  renders a point tall. The frame is the one value that cannot lie.
- **When a reproduction comes back green twice, stop writing reproductions and instrument the app.**
  Five green ones proved nothing about a bug already caught on tape. What went red was a test of the
  *contract* the tape named — nothing is assembled before there is a room — not of the pixels.
- **A probe proves nothing until it proves it arrived with the motion switched on.** A run that never
  reached the state reads exactly like one that did — a drag aimed at a list that was never populated
  landed on a button and produced confident, worthless numbers — and `-UITestingNoAnimations` turns motion
  into an instant snap, so the measurement blames the code for the harness.

## Instruments

- **`PinwheelRecorder`** — `-PinwheelRecord` writes `session.log` to the app's tmp: every touch with the
  name of what it hit, every navigation, every reaction with its state, keyboard frames, and geometry
  when it changes. For anything a person drove by hand. Appends across launches; read it with
  `xcrun simctl get_app_container <udid> <bundle> data`.
- **`PinDisplayListCapture`** (SwiftUI tree) and **`PinUIKitCapture`** (UIView tree) — real frames for any
  layout question.
- **A `CADisplayLink` tape** for motion: sample `layer.presentation()` and write to
  `NSTemporaryDirectory()`. `simctl io recordVideo` drops frames badly enough to be useless.
- **`RenderPreview`** on the catalog's permanent `#Preview`, and `simctl launch -PinwheelPreview <id>` to
  deep-link a booted simulator.
- **`Scripts/sweep.sh --preview`** snapshots every component and tweak variant; `--capture --only=<id>`
  re-checks one component's Figma IR. Never hand-roll `simctl` against a pinned UDID — the sweep owns its
  own simulator, and a hardcoded device launches nowhere while you read a stale result.
- **Dump the runtime rather than stopping at a search result.** Two private keyboard flags looked right
  and both were wrong; enumerating every property on the live object, twice, settled it in one run.
- **A shake says which build is running** (`PinwheelShakeToShowBuild`). iOS delivers a shake as a
  `motionShake` event to the first responder, so a controller that takes first responder catches it;
  the simulator has no accelerometer, so CoreMotion cannot see one there at all.
- **The Xcode MCP** for build and verify (`BuildProject`, `RenderPreview`, `RunSomeTests`);
  `xcodebuild`/`simctl` are the fallback. Setup and its gotchas live in the `xcode-mcp` skill.

## Merge gate

Actions is paused, so the gate is local: run both tiers and only merge a commit whose message says they
ran green.

```
~/bin/test-sim -s PinwheelTests
~/bin/test-sim -s Demo -o DemoTests
```

The `Tests: unit NN/NN + hosted NN/NN green (local xcodebuild)` trailer is the signal, and a PreToolUse
hook blocks a merge whose tip commit lacks it.

## House style

- **SwiftUI-first with UIKit compatibility.** No `import UIKit` in SwiftUI-first views, examples or call
  sites; keep UIKit to compatibility types and clearly named bridges.
- **Theme is law.** Every surface resolves provider-backed tokens (`PinwheelTheme`), never Apple's system
  styles, and API is shaped so the system-style path is unrepresentable — `PinLabel.font` takes a themed
  `PinTextStyle`, not a `Font`.
- **Colours are trait-reactive, fonts are not.** A font token resolves once against the traits current at
  the read, so SwiftUI font call sites take the theme explicitly (`PinTextStyle.font(in:)`).
- **A presentation takes its traits from the window**, so the theme is written there, never on presented
  content.
- **One implementation per component**: a SwiftUI `Pin*` plus a thin `UIPin*` shell that hosts it. The
  UIKit twin is `UIPin*`, never `UIKitPin*`; spelled-out `UIKit` is a descriptive qualifier only
  (`PinUIKitCapture`, `isUIKitHosted`).
- **Shared vocabularies are top-level types** (`PinTextStyle`, `PinState`).
- **SwiftUI-native API**: bare initializer plus chained themed modifiers, mirroring SwiftUI's own names.
  Unprefixed on our types; `pinwheel`-prefixed only when extending a SwiftUI type.
- **Catalog ids derive from title + tags** — there is no manual `id:`, and deep links and persistence key
  off them, so a title must be unique within its scope.
- **One file per abstraction.**
- **A comment explains code; a docstring states a contract.** An explanation belongs in a name, a named
  test or `LEARNINGS.md` — write the test for the behaviour a comment describes and the comment dies with
  it. A docstring earns its place on a public seam where the signature cannot say what to pass or when to
  leave it off, and it says nothing about how the code works.
