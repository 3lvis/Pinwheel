# Agent Guidelines

How we work in Pinwheel. Portable iOS conventions live one level up (`~/code/<org>/ios/AGENTS.md`) and are
inherited, and this file carries only what is Pinwheel's own. **Why** any of this is the way it is — the measurements, the
traps, the bugs behind each rule — is carried by the rule itself, which is what a graduated lesson looks
like; `git log --diff-filter=D -- LEARNINGS/` reads the notes each one came from. What you learn next goes
in a file of its own, `LEARNINGS/<YYYY-MM-DD-HHMM>-<slug>.md`, so branches writing at once stay clear of
each other; the rules and the periodic pass that grades them are in [`LEARNINGS.md`](LEARNINGS.md). Keep
*this* file to what a session needs nine times in ten.

[`VOICE.md`](VOICE.md) is how we write — PRs, commits, comments, docs, error copy — and it carries the
Swift API Design Guidelines whole, so a naming question is answered by reading it. Read it before you write.

## Working rules

How a session proceeds.

- **Measure and reproduce before fixing.** A cause is something a run showed you. Guessing costs a build
  and a launch per round, and a wrong guess wears the same face as a right one that left the bug in place.
- **When a refactor fights back, suspect the refactor.** Code that resists being moved is usually saying
  the move is wrong. Instrumenting harder finds the mechanism and misses the mistake — a card made to
  hold content as well as move it came out one point tall, and three rounds went into the constraints
  before the second job was the answer.
- **Ask the app: a layout fact is a test.** Screenshots are for external references. Pixel-scanning this
  app has produced contradictory numbers, numbers taken off the home screen, and wrong point scales.
  Every question has an instrument below — reach for it before writing one.
- **Verify before claiming done**, and report what you actually observed, failures included.
- **Hand a build over by name, and let the app confirm it.** Shaking shows `build HHmm`, read from the
  running binary's own timestamp, and the recorder's first line carries the same — so open a handover
  with the label and the person holding the phone can check rather than trust. Anything written *beside*
  the binary can describe a different one, which is the staleness it exists to catch.
- **A warning only re-emits on a build that recompiles.** An incremental build skips unchanged files, so
  a clean count comes from a fresh `-derivedDataPath`. Five checks in a row read zero off a build whose
  every file was already up to date.
- **If something should be off, turn it off.** Leaving it on and undoing what it does hides the effect
  from you while the code that reads the flag still sees it, and whatever it used to handle needs a new
  owner you can name.
- **The folder layout *is* the project structure** — both targets are file-system-synchronized groups, so
  adding or moving a file is a `project.pbxproj`-free edit and a new folder is a real decision.

## What a component owes at runtime

- **A container owns the space around and between its children; a child owns only what is inside it.**
  Both axes, and a constraint is space — so every constraint a child holds stays inside it, and it
  publishes a measurement only where it owns the number: `intrinsicContentSize` for a view sized by its
  own content, silence for one whose size a value above it decides. Only the thing that can see both
  sides of a gap can balance it, so the gap between two rows belongs to whatever holds them — a section
  for its items, the tray for its sections — and how far they stand off an edge belongs there too. A
  child that pads its own outside makes every gap the sum of two decisions nobody took together.
- **A gesture and the animation that follows it are one motion.** It leaves at the speed the finger let
  go at, it stays interruptible until it settles, and where it ends up is wherever it would come to rest
  if left alone.
- **A scroll view scrolls only when its content outgrows its room.**
- **A hosting controller reports the size its old content had.** Swapping what a
  `UIHostingController` shows leaves its view at the previous height — a 60-row list laid out 20 points
  tall, with nowhere to scroll and every row answering `Not hittable` while sitting in the accessibility
  tree at full strength. `sizingOptions = .intrinsicContentSize` is what makes it report what SwiftUI drew.
- **A view measures once it has joined its parent, and only then.** A controller's `viewDidLoad` runs the
  moment `.view` is first touched, which is ahead of the caller adding it — so anything needing a room
  waits for `didMove(toParent:)`. Measured detached, a tray built itself 89 points wide and flat, and
  every correction after that landed somewhere wrong.
- **A component captures with zero cooperation, and that is the contract.** Every `Pin*` is byte for
  byte what a consumer would write, and the engine derives everything from what renders: structure from
  geometry, names from reflection, tokens by value-matching the rendered colour and radius against the
  registries. Reverse-engineer the real thing rather than shaping a component so the capture can read it,
  which is why the list demo stays a raw `List`. Which engine runs follows the item's hosted *world*
  (`PinwheelItem.isUIKitHosted`) — routing on the `.uiKit` display chip instead captured a tagged UIKit
  demo as one flat image.
- **A value the platform owns is read at runtime.** Read it and the layout is right on hardware and OS
  versions released long after this. Where the platform keeps it private, reimplement only what holds
  still — a corner's curve is the same shape on every device, while its radius varies.

## Built to be tested

An experience is testable when the facts it rests on live somewhere a test can reach without a screen.
These put them there; the section below says where the test then goes.

- **One place decides and one place draws: behaviour is a pure value, and a view draws what it decided.** Count states rather than screens — a control that is valid or invalid and enabled
  or disabled already has four — and every rule the value holds is then a test, sequences included. Almost
  every bug here has been the same shape: a second copy of the state, or a second path that animates.
  Delete the copy rather than syncing it.
- **Every state is a case you match on.** Where `nil` would mean the value lives in another state, make
  that state a case, so it is readable exactly where it exists; where the value is unavailable, throw.
  That rules out the three stand-ins — an optional, a default, a two-phase setup. Dependencies arrive
  through `init`: a thing that lives on a container, a clock and something to show takes all three at
  birth, and every protocol ships a real implementation and a stub so the seam is usable from a test the
  day it is made. A fallback is either the answer or a lie standing in for a state — a height quietly
  keeping what was there before drew a 200-point tray at 794. A placeholder you reach for because a value
  has to wait for `super.init` is the type telling you it belongs to whatever already exists by then,
  which is the parent, and a setup method that fills it in later just moves the gap.
- **A parent composes its children and asks them what they measure, and that is the whole of its job.**
  Every reach spans one level — downward direct, upward through a closure or a protocol — and each child
  holds one job and is pure where it can be: the tray's geometry and its machine are pure values, and the
  chassis that draws them owns exactly that. Deciding and drawing belong elsewhere. Size is a red herring
  — a parent with one child to compose is a pass-through, and one that assembles six parts is doing its
  job at the size that job is.
- **A child answers to its own delegate and reports upward in its own words.** The body is its scroll
  view's delegate, and what it tells the tray is "pulled down by 40". A parent adopting its child's
  protocol drags the child's vocabulary a level up, where it belongs to nobody.
- **Containment is a UIKit job.** SwiftUI supplies leaves — a row, a title, a field. Anything that holds,
  lays out, scrolls or routes a gesture is a `UIView` we own, which makes it an ordinary object with an
  ordinary frame a test reads straight off. Asking SwiftUI to contain is what makes gestures fight across
  the seam, representables vanish without a scene, and children reachable only by walking a tree somebody
  else owns.
- **Where the framework owns the mechanism, move the seam rather than the mechanism.** Auto Layout, the
  keyboard and the render server are the implementation itself, so a fake of one proves only that the fake
  works. The boundary goes above them, a pure value deciding the number where every rule is a test, and
  below them, the frame that came out. What sits between is left holding the mechanism alone.
- **Behaviour waits on an event, and a timer is a guess about the world.** Something that happens when a
  motion ends rides the animation's completion; something that depends on what the world is doing asks the
  world — a private API answering outright beats a stopwatch estimating.

## Testing

Write the test at the lowest rung that can hold the fact. Moving up takes a reason beyond convenience.

| Target | Holds | Runs |
|---|---|---|
| **`PinwheelTests`** | the library's own behaviour — logic, geometry, tokens, rendering, the capture engine. **The default home.** | hostless SwiftPM |
| **`DemoTests`** | facts needing a live app: anything **presented**, anything needing a real scene or a real keyboard, and Demo-target code that lives outside the package | **hosted by `Demo.app`** |
| **`DemoUITests`** | throwaway probes only, **empty at rest** | XCUITest |

- **A bug gets a failing test first, and the test has teeth: it fails against the un-fixed code, for the
  right reason.** Red, run it, then fix, with the test landing in a step of its own ahead of any source
  edit. Commit the fix before reverting to prove the red, or the revert silently eats it, and when a fix
  ships without a red first say so plainly. Only bugs earn a test this way; everywhere else prefer making
  the mistake unrepresentable over asserting it is absent.
- **A fact that needs an app is still a testable fact.** `DemoTests` is hosted and ships a harness,
  `HostedView`: `window(showing:)` flips `_AXSSetAutomationEnabled` so SwiftUI fills its accessibility
  tree and labels, frames and `accessibilityActivate()` become readable; `presentation(in:)` waits for a
  presented view to join the window; `settledPresentation(in:)` waits for a detent to stop moving. A
  number the framework *produces* rather than takes — an intrinsic size, where a system guide has moved
  to — is the framework's own answer, so this is the rung that can read it.
- **A UI test is an instrument, and it leaves with the change that fixes what it found.** Driving the app
  to watch a change work goes red while the fix is absent and is deleted once it lands, leaving the unit
  test for what it localised. A workaround held against SwiftUI or UIKit, out of reach of every lower rung,
  may keep a permanent one — with teeth *and* a place in the merge gate, since a guard outside the gate is
  one nobody runs and it rots quietly. Coverage alone leaves a UI test unjustified.
- **Drive a layout with constraints; assert the frame.** A frame written on a hosted view hands it a
  height it was spared working out, so the test measures the setter rather than the layout — and a
  constraint read back asserts the same thing. That reads green while the constraint sits inactive, while
  a competing one wins, and while an optional one is dropped in silence and the view renders a point tall.
  The frame is the one value that answers for what actually happened.
- **When a reproduction comes back green twice, switch to instrumenting the app.** Five green ones left a
  bug already caught on tape exactly where it was. What went red was a test of the *contract* the tape
  named: assembly waits for a room.
- **A probe reports its arrival and its motion before it reports a number.** A run that fell short of the
  state reads exactly like one that reached it — a drag aimed at a list still waiting for rows landed on a
  button and produced confident, worthless numbers — and `-UITestingNoAnimations` turns motion into an
  instant snap, so the measurement blames the code for the harness.

## Instruments

- **`PinwheelRecorder`** — `-PinwheelRecord` writes `session.log` to the app's tmp: every touch with the
  name of what it hit, every navigation, every reaction with its state, keyboard frames, and geometry
  when it changes. For anything a person drove by hand. It appends across launches; read it with
  `xcrun simctl get_app_container <udid> <bundle> data`.
- **`PinDisplayListCapture`** (SwiftUI tree) and **`PinUIKitCapture`** (UIView tree) — real frames for any
  layout question.
- **A `CADisplayLink` tape** for motion: sample `layer.presentation()` and write to
  `NSTemporaryDirectory()`. It holds the frames `simctl io recordVideo` drops, which are the ones a
  transition lives in.
- **`RenderPreview`** on the catalog's permanent `#Preview`, and `simctl launch -PinwheelPreview <id>` to
  deep-link a booted simulator.
- **`Scripts/sweep.sh --preview`** snapshots every component and tweak variant; `--capture --only=<id>`
  re-checks one component's Figma IR. The sweep owns its own simulator and resolves it by UDID, so reach
  for the script rather than `simctl`: a hardcoded device launches nowhere while you read a stale result.
- **Dump the runtime rather than stopping at a search result.** Two private keyboard flags looked right
  and both were wrong; enumerating every property on the live object, twice, settled it in one run. The
  capture engine reads SwiftUI's private shape storage by field name, so an OS bump empties it silently
  and the red tests look unrelated to each other — `FixedRoundedRect` carried `cornerSize` through
  iOS 26 and carries `radii` from iOS 27. Probe the storage, which named the change in one run after
  three rounds of theorising about the symptom.
- **A shake says which build is running** (`PinwheelShakeToShowBuild`). iOS delivers a shake as a
  `motionShake` event to the first responder, so a controller that takes first responder catches it;
  CoreMotion reads a real accelerometer, which a simulator leaves it without.
- **The Xcode MCP** for build and verify (`BuildProject`, `RenderPreview`, `RunSomeTests`);
  `xcodebuild`/`simctl` are the fallback. Setup and its gotchas live in the `xcode-mcp` skill.

## Merge gate

Actions is paused, so the gate is local: run both tiers, and a commit merges once its message says they
ran green.

```
~/bin/test-sim -s PinwheelTests
~/bin/test-sim -s Demo -o DemoTests
```

The `Tests: unit NN/NN + hosted NN/NN green (local xcodebuild)` trailer is the signal, and a PreToolUse
hook blocks a merge whose tip commit lacks it.

## House style

- **SwiftUI-first with UIKit compatibility.** `import UIKit` belongs to compatibility types and clearly
  named bridges, which keeps SwiftUI-first views, examples and call sites free of it.
- **Theme is law.** Every surface resolves provider-backed tokens (`PinwheelTheme`), and API is shaped so
  the system-style path is unrepresentable — `PinLabel.font` takes a themed `PinTextStyle`.
- **Colours are trait-reactive; a font resolves once, against the traits current at the read.** So
  SwiftUI font call sites take the theme explicitly (`PinTextStyle.font(in:)`).
- **A presentation takes its traits from the window**, so the theme is written there rather than onto
  presented content.
- **One implementation per component**: a SwiftUI `Pin*` plus a thin `UIPin*` shell that hosts it. The
  UIKit twin is `UIPin*`, mirroring Apple's own prefix; spelled-out `UIKit` stays a descriptive qualifier
  (`PinUIKitCapture`, `isUIKitHosted`).
- **Shared vocabularies are top-level types** (`PinTextStyle`, `PinState`).
- **Rows get a tray, a screen gets a sheet.** Every catalog surface is a `pinwheelTray(path:)` sequence,
  the array being the navigation, so one title bar serves every depth and the leading control is derived
  from depth. A picker is a tray too, since a `Menu` renders through UIKit with the system font and takes
  the system font throughout. The one presentation that stays a sheet is a presented catalog item, which
  carries its own chrome.
- **SwiftUI-native API**: bare initializer plus chained themed modifiers, mirroring SwiftUI's own names.
  Unprefixed on our types, and `pinwheel`-prefixed where it extends a SwiftUI type.
- **Catalog ids derive from title + tags**, which deep links and persistence key off, so a title is
  unique within its scope and the `id:` is computed for you.
- **One file per abstraction.**
- **A comment explains code; a docstring states a contract.** An explanation belongs in a name, a named
  test or a file in `LEARNINGS/` — write the test for the behaviour a comment describes and the comment
  dies with it. A docstring earns its place on a public seam where the signature leaves open what to pass
  or when to leave it off, and it stops at the contract.
