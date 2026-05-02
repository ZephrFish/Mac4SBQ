Resolved.

**Root cause:** `~/.claude/hooks/session-init.sh` only swept stale agent manifests via `.active-*` marker files. When the marker was deleted first (by the marker TTL sweep, partial cleanup, or external removal), the manifest was invisible to the cleanup loop and stayed `status=active, outcome=null` permanently — accumulating as "phantom agents" across sessions.

**Fix:** Added a manifest-driven orphan sweep (`DEC-ORPHAN-SWEEP-001`) to `session-init.sh` that scans manifests directly. Any manifest with `status=active, outcome=null` older than 2h with no live marker is sealed as crashed via `finalize_trace` — the same code path the marker-driven sweep uses. The 2h threshold matches `DEC-STALE-THRESHOLD-001` (1h marker TTL) plus a 1h safety margin so a long-running agent that just lost its marker isn't prematurely sealed.

**Macbequick phantoms (sealed):**
- `implementer-20260429-114316-311bc3` → status=crashed, outcome=crashed
- `tester-20260429-195142-311bc3` → status=crashed, outcome=crashed

**Verification:**
```
$ find ~/.claude/traces -maxdepth 2 -name manifest.json -print0 \
    | xargs -0 -I {} jq -r 'select(.project=="/Users/zephr/tools/macbequick" and .status=="active") | .trace_id' {} \
    | wc -l
0
```

Closes #10, #11, #12. Refs closed #2-#9 — single-comment trail for Future Implementers.
