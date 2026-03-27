---
name: Never remove print statements
description: User's print/checkpoint statements must never be deleted or modified when editing code
type: feedback
---

Never remove, modify, or "clean up" the user's print statements — especially checkpoint prints (e.g. "chk 1", "entercall: chk 2", separator lines). They are intentional debugging aids.

**Why:** User relies on these for runtime debugging and gets frustrated when they disappear during edits.

**How to apply:** When editing any file, preserve all existing print statements exactly as they are. Only add new prints if needed for new code paths.
