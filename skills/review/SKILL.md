---
name: review
description: Review requested changes or an entire repository for design, naming, correctness, and tests. Use when the operator asks for a code review.
---

# Code review
Review either the requested changes or the whole repository, depending on the operator's request.

## Execution
Determine the scope first: for requested changes, the diff and the surrounding code; for a repository, its structure and the relevant areas. Then run the four categories in parallel: launch one subagent per category, all in a single parallel batch. Each task prompt must be self-contained and must include the scope, the full text of its category, and the finding format: one-line findings ordered most to least severe, each with a severity, a `file:line` reference, the problem, and the recommended change.

Write the final review yourself from the four results: drop exact duplicates, assign the `{category}.{finding}` IDs, and follow the Output section. Subagent output is not shown to the operator.

## Review categories
Assess each category independently. Do not let a finding in one category substitute for assessing the others, and do not merge unrelated findings merely because they affect the same lines. Report a category even when it has no findings.

### 1. Design and abstractions
Evaluate structure, responsibilities, interfaces, and abstraction boundaries. Check whether abstractions are justified, reduce complexity, preserve locality of behavior, and make the code easier to read and reason about. Prefer deeper modules over shallow ones. Flag needless indirection, premature generalization, and abstractions that merely relocate details. Check that code is idiomatic: it follows the language's and repository's conventions and avoids needless cleverness and special cases.

### 2. Naming and comments
Evaluate variables, functions, types, tests, and other identifiers for clarity and consistency with repository conventions. Comments should be avoided in general. They are acceptable only when they explain non-obvious choices (the WHY), not the WHAT, unless the logic is genuinely complex enough to justify it. Code should be reasonably self-explanatory; its readability should come from categories 1 and 2, not from comments.

### 3. Correctness
Evaluate functional behavior, error handling, boundary conditions, state transitions, concurrency, security, resource handling, and compatibility with existing behavior. Identify bugs and likely regressions, including issues that are not directly covered by tests.

### 4. Tests
Evaluate whether tests protect meaningful behavior and likely regressions rather than implementation details. Check coverage of changed behavior, edge cases, failure paths, useful assertions, arrange/act/assert structure, test isolation, determinism, and repository testing conventions.

## Output
Write one section per category, in this order. Do not add a summary section.

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
