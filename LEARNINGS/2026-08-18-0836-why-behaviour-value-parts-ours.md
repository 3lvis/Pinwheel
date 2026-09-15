**Why behaviour is a value, and which parts of that are ours**

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
*— Elvis, 2026-08-18 08:36*
