**Measure a transition from inside the app, not from a recording.** A `CADisplayLink` writing the
tray's presentation-layer frame and the guide's frame to a file each frame answered in one run what
four rounds of pixel-detectors on `simctl` video could not: the detectors kept latching onto the
keyboard's edge or the content behind the tray, and `simctl io recordVideo` drops the very frames a
transition lives in. Read the file out of the app container afterwards. Note the guide reports its
*model* value, so it shows the keyboard's target rather than where it is drawn — for that, look at
frames.
*— Elvis, 2026-08-18 08:36*
