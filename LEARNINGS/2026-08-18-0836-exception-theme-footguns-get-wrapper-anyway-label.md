**Exception — theme footguns get a wrapper anyway.** `Label → PinLabel` because raw `Text(...).font(.body)` silently resolves to Apple's system style (see Theme below). The test is "does the raw primitive bypass the theme?", not just "does a primitive exist?".
*— Elvis, 2026-08-18 08:36*
