---
name: review
description: Review requested changes or an entire repository for design, naming, correctness, and tests. Use when the operator asks for a code review.
---

# Code review
Review either the requested changes or the whole repository, depending on the operator's request.

## Execution
Determine the scope first: for requested changes, the diff and the surrounding code; for a repository, its structure and the relevant areas. Then run the four categories in parallel: launch one subagent per category, all in a single parallel batch. Each task prompt must be self-contained and must include the scope, the full text of its category, and the finding format: one-line findings ordered most to least severe, each with a severity, a `file:line` reference, the problem, and the recommended change.

Subagent output is not shown to the operator. After the subagents return, run Triage, then Elaborate, then Implement.

## Triage
Verify every finding yourself against the code before showing anything. Drop exact duplicates and false positives, and state in one line per dropped finding what it was and why it is wrong or a duplicate.

Present the remaining findings as the report below, then ask the operator about each one in a single `question` call. The question text is the finding line. The options are:
- one option per candidate solution, labeled "Move forward: <solution>", when the finding has two or more plausible solutions;
- a single "Move forward" option when the finding has one obvious, straightforward solution;
- "Elaborate" to get the finding explained in plain words before deciding;
- "Skip".

Recommend the strongest solution when it is clear, and recommend "Skip" for findings marked "theoretical" and for low-severity findings not worth the churn.

```markdown
# Review
## 1. Design and abstractions
- 1.1 **high** `src/auth/session.rs:42`: Token check duplicated in two call sites; extract a single guard function.
- 1.2 **low** `src/db/pool.rs:88`: Connection wrapper adds a layer without hiding any detail; inline it.
## 2. Naming and comments
No findings.
## 3. Correctness
- 3.1 **critical** `src/api/handler.go:120`: Missing nil check on the decoded payload; return 400 on decode failure.
## 4. Tests
- 4.1 **medium** `src/api/handler_test.go:35`: Asserts only the 200 path; add a case for the decode failure path.
```

Findings are one line each, formatted as in the template; the ID is `{category number}.{finding number}`. Use `critical`, `high`, `medium`, or `low`, sorted within the section from most to least severe. Focus on actionable findings.

## Elaborate
Go through, one at a time, only the findings the operator marked "Elaborate", ordered most to least severe across all categories, critical first. For each finding:
1. Explain the problem in plain words, assuming no knowledge of this part of the codebase: what the code does now, what is wrong with it, and what goes wrong in practice.
2. Lay out the candidate fixes side by side.
3. Ask whether to proceed with a fix or skip. If the operator picks a fix, record the choice.
4. Move to the next finding. If the operator skips, note it and continue.

Do not change any code during this phase. Findings already marked "Move forward" or "Move forward: <solution>" keep that decision and need no elaboration. Collect all decisions first, then run Implement.

## Implement
Apply the fixes recorded in the Elaborate phase, most severe first, and adjust or add tests for each changed behavior. Skip nothing that was agreed to. If a fix turns out to be infeasible during implementation, stop and ask the operator before substituting another solution while it is the current finding.

## Review categories
Assess each category independently. Do not let a finding in one category substitute for assessing the others, and do not merge unrelated findings merely because they affect the same lines. Report a category even when it has no findings.

### 1. Design and abstractions
Evaluate structure, responsibilities, interfaces, and abstraction boundaries. Check whether abstractions are justified, reduce complexity, preserve locality of behavior, and make the code easier to read and reason about. Prefer deeper modules over shallow ones. Flag needless indirection, premature generalization, and abstractions that merely relocate details. Check that code is idiomatic: it follows the language's and repository's conventions and avoids needless cleverness and special cases.

### 2. Naming and comments
Evaluate variables, functions, types, tests, and other identifiers for clarity and consistency with repository conventions. Comments should be avoided in general. They are acceptable only when they explain non-obvious choices (the WHY), not the WHAT, unless the logic is genuinely complex enough to justify it. Code should be reasonably self-explanatory; its readability should come from categories 1 and 2, not from comments.

### 3. Correctness
Evaluate functional behavior, error handling, boundary conditions, state transitions, concurrency, security, resource handling, and compatibility with existing behavior. Identify bugs and likely regressions, including issues that are not directly covered by tests. For each finding, judge whether it can happen in practice with the real inputs, configuration, and call sites. Mark findings that are only possible in theory and won't happen in real life as "theoretical" in the severity slot and do not count them as real bugs.

### 4. Tests
Evaluate whether tests protect meaningful behavior and likely regressions rather than implementation details. Check coverage of changed behavior, edge cases, failure paths, useful assertions, arrange/act/assert structure, test isolation, determinism, and repository testing conventions.
