**A pinned offset destroys the quantity you are deriving from it**

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
*— Elvis, 2026-08-18 08:36*
