**The view measures the keyboard; the machine decides what the measurement means.** The overlay used to
keep its own `keyboardInset` and derive opening/open/closing from it, updating it only when the machine's
view of the keyboard changed — so a *commanded* dismissal left the copy stuck at 311 forever. The next
push then read a rising keyboard as already settled, ran our spring against its animation, and the card
sagged 40pt before climbing (measured: one reversal on the second push, none on the first). The copy was
the bug, so it is gone: the view reports a height and `PinTrayMachine.keyboard(measuring:)` draws the
conclusion. Structural, not asserted — there is no second copy left to go stale.
*— Elvis, 2026-08-18 08:36*
