---
name: grill
description: Grill the user about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user until you reach a shared understanding. Treat the plan as a design tree: each decision branches into the decisions that depend on it.

Work the tree in rounds. The frontier is every decision whose prerequisites are settled: the questions you can ask now without guessing at answers you have not heard yet. Ask the whole frontier in one round with a single `question` call that batches every question in the round. One call per round, never one call per question. Wait for the user's answers before the next round.

Build each question in the call like this:

- `header`: a short tab label that names the decision, not the answer.
- `question`: the question body. It may span paragraphs.
- `options`: the concrete ways to answer, your recommended answer first and marked `(Recommended)`. Give two to four real choices whenever the decision has them. The operator then answers with one keystroke instead of typing. Put the trade-off of an option in its description when the label alone does not make the choice clear.
- `multiSelect`: set when the choices are not mutually exclusive.

The question tool appends its own `Type your answer` entry. Never add a catch-all option. Ask a plain open question only when every menu choice would be a guess that biases the operator. That case is rare.

Recommend an answer for every question. Do not leave the recommendation in prose outside the call when an option can carry it. Do not pad a menu with filler choices: every option must be one you would accept.

```text
Question
Should sessions expire server-side?

1. Yes, sliding 30-minute idle timeout (Recommended)
   No revocation list, matches the existing token TTL.
2. Yes, hard 8-hour expiry
   Easier to reason about, forces a re-login mid-day.
3. No, keep tokens until refresh
   Less code, but a leaked token lives until refresh.
4. Type your answer
```

Each round of answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. If a question's answer depends on another question still open in this round, it belongs to a later round.

Finding facts is your job. When a question needs a fact from the environment (filesystem, tools), dispatch a sub-agent to find it. Do not ask the user for anything you can look up yourself. Do not block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent. Ask the rest of the frontier now. The decisions belong to the user: put each to them and wait.

The session ends when the frontier is empty: every branch visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.
