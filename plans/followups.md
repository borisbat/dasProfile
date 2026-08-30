# dasProfile follow-ups

## Progress visibility during a capture

`main.das --json` runs the suite in a child through `popen` and parses its lines at the
end; nothing reaches the log until the JSON is written, so a 25-minute capture gives no way
to tell progress from a hang. Echo every parsed entry to stderr as it arrives
(`[test 12/16] "DAS AOT", "queen", 0.000132, 4396`), so `tail -f` on the log shows the
lane and test in flight; the JSON still comes only from the full pass.

Ruled 2026-08-30 (Boris): "its not good to sit blind and guess 'are we there yet, are we stuck'".
