<!-- Written the way we write everything else here — VOICE.md. -->

## Why

<!-- A fix says what was wrong, in plain words. A feature says what was asked for, and what Pinwheel
     can do now. -->

## The approach

<!-- How you fixed or built it. Explain a piece of the code only where that saves the reviewer time. -->

## Screenshots

<!-- Required whenever the change is visible: the reviewer should never have to build the branch
     to see it. A fix shows before and after. A feature shows one column, unless it is a revamp,
     where the old one belongs beside it. The table holds each image to half the width.

<table>
  <tr><td align="center"><b>Before</b></td><td align="center"><b>After</b></td></tr>
  <tr><td><img src="" width="100%"></td><td><img src="" width="100%"></td></tr>
</table>

-->

## Testing

<!-- Both tiers, per the merge gate — `test-sim -s PinwheelTests` and `test-sim -s Demo -o DemoTests` — and the commit carries the `Tests: unit NN/NN + hosted NN/NN green` trailer. -->

## Learnings

<!-- What the task taught, as its own file: LEARNINGS/<YYYY-MM-DD-HHMM>-<slug>.md. Where it taught you
     little, one word here covers it.

     And where a line of AGENTS.md earned its keep on this task, cite it:

         **Earned its keep:** AGENTS.md § Testing — "a test that passes before the fix proves nothing"

     Those citations are the only read signal either document has, and both directions of the two-monthly
     pass run on them: a learning nobody reached for gets pruned, and an AGENTS line nobody cited goes back
     to being a learning. A line you were glad of is worth the ten seconds. -->
