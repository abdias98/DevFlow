# Deferred Backlog

Persistent record of scope-adjacent findings not fixed because they fell outside the Core or Impact Zone of the cycle that found them (rules.md → Scope-Locking — Three Zones). Read by the Brainstormer and Architect at the start of a cycle touching the same area, so what was skipped once doesn't stay skipped forever.

| ID | File | Reason | Severity | Cycle | Date | Status |
|----|------|--------|----------|-------|------|--------|
| D1 | src/store.js | writeAll uses non-atomic writeFileSync; a crash mid-write can truncate the store (pre-existing, now also used by addMany) | 🟢 INFO | notes-import | 2026-09-21T04:38:32Z | open |
| D2 | src/store.js | readAll lets a corrupt store file surface as an uncaught SyntaxError (stack trace) instead of a NoteError; affects add/list/import (pre-existing) | 🟢 INFO | notes-import | 2026-09-21T04:38:32Z | open |
| D3 | src/store.js | Concurrent read-modify-write on the store file: two parallel add/import processes can lose a whole batch while both report success (concurrency.md §2). Needs lockfile or temp+rename; pre-existing for add, wider window for import | 🟠 INCOMPLETE | notes-import | 2026-09-21T04:42:10Z | open |
| D4 | src/store.js | Imported notes cross a new trust boundary: id has no length/format bound and id/title allow control chars, so list can echo forged lines/ANSI escapes (security.md §1). Tightening validateNote also changes add | 🟢 INFO | notes-import | 2026-09-21T04:42:10Z | open |
| D5 | src/store.js | addMany error for non-object/bad-id entries does not name the entry index; empty batch still reads the store | 🟢 INFO | notes-import | 2026-09-21T04:42:10Z | open |
| D6 | test/store.test.js | Move store.addMany tests out of cli.test.js into a test/store.test.js mirroring src/store.js (testing.md §7) | 🟢 INFO | notes-import | 2026-09-21T04:42:10Z | open |
