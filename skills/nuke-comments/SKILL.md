---
name: nuke-comments
description: Strip comments with a hard bias towards deletion; agents add comments for no reason. Use after every edit you make.
---

# Nuke comments

Apply to the requested changes or the files the operator names. Coding agents sprinkle comments by default; that is noise, and most of it is theirs. When in doubt, delete. Code must be self-explanatory. If a comment seems needed, first rename, restructure, or extract so it is not; when cleaner code makes a comment obsolete, tell the operator. A comment survives only if even clean code cannot carry its meaning: a workaround, a linked bug, a hidden constraint, a public-API contract the signature cannot show. Everything else dies: narration, restated identifiers, commented-out code, banners, changelogs, stale TODOs, docstrings restating the signature. A real reason buried in noise becomes one line or dies.

Remove orphaned blank lines. Run a formatter or syntax check if one exists. Report one line per file: deleted, rewritten, kept.
