**A `UIViewPropertyAnimator` stopped mid-flight leaves a frame where it stopped, and the constraint it was
animating towards never pulls it back.** `stopAnimation(true)` writes the in-flight values into the model,
while the height constraint already holds its target. So the next layout pass finds nothing dirty and the
view stays at whatever height it had reached. A tray that opened on a filling tray drew a card 0 points
tall under a full dim: learning it filled sprang the unpresented card, and the arrival stopped that
spring a frame in. The tray's own trace said `card=756` while `PinwheelRecorder` geometry read
`cardHeight=0`, and that disagreement between what was decided and what was drawn named the fault in one
run. Fix it by never starting the second motion, which here meant a fresh tray counts as arriving.

*— Elvis Nunez, 2026-10-08 20:05*
