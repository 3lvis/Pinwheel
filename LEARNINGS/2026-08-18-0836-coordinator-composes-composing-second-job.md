**A coordinator composes, and composing is not a second job**

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
*— Elvis, 2026-08-18 08:36*
