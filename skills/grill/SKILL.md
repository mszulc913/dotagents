---
name: grill
description: Grill the user about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user until you reach a shared understanding. Treat the plan as a design tree: each decision branches into the decisions that depend on it.

Work the tree in rounds. The frontier is every decision whose prerequisites are settled: the questions you can ask now without guessing at answers you have not heard yet. Ask the whole frontier in one round with a single `question` call that batches every question in the round. One call per round, never one call per question. Wait for the user's answers before the next round.

Build each question in the call like this:

- `header`: a short tab label that names the decision, not the answer.
- `question`: the question body. It may span paragraphs or list choices.
- `options`: the meaningful choices, with your recommended answer first and marked `(Recommended)`. A custom answer is always available, so options are optional; ask a plain open question when no choices make sense.
- `multiSelect`: set when the choices are not mutually exclusive.

Recommend an answer for every question. Do not leave the recommendation in prose outside the call when an option can carry it.

Each round of answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. If a question's answer depends on another question still open in this round, it belongs to a later round.

Finding facts is your job. When a question needs a fact from the environment (filesystem, tools), dispatch a sub-agent to find it. Do not ask the user for anything you can look up yourself. Do not block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent. Ask the rest of the frontier now. The decisions belong to the user: put each to them and wait.

The session ends when the frontier is empty: every branch visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.
