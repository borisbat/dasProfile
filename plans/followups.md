# dasProfile follow-ups

## Progress visibility during a capture

`main.das --json` runs the suite in a child through `popen` and parses its lines at the
end; nothing reaches the log until the JSON is written, so a 25-minute capture gives no way
to tell progress from a hang. Echo every parsed entry to stderr as it arrives
(`[test 12/16] "DAS AOT", "queen", 0.000132, 4396`), so `tail -f` on the log shows the
lane and test in flight; the JSON still comes only from the full pass.

Ruled 2026-08-30 (Boris): "its not good to sit blind and guess 'are we there yet, are we stuck'".

## dictionary swings between processes on the 3990X

Every other row reads 0-2 % spread on the cold zen2 box; dictionary reads 8-48 % on the
compiled lanes and 9-25 % on the interpreted ones, and the samples are bimodal, not noisy:
das interpreter 17.8 / 18.7 / 29.7 / 30.1 / 30.6 ms, das AOT 10.4 / 11.0 / 11.2 / 14.8 / 16.5 ms,
das JIT 11.5 / 12.5 / 13.0 / 16.2 / 23.9 ms (2026-08-30 capture). The M1 reads 1-6 % on the
same row. Per-process heap or hash-table placement is the suspect - CCX-local L3 versus
cross-die memory for the table, or where the [init] pin lands the process - and it is the
one cell the budget cannot settle. Look at it with the table size and the pinned core
logged per sample.
