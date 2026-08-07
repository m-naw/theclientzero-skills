---
name: principles-shipping-gate
description: Use when about to merge a PR, claim completion on non-trivial code, or declare a refactor done
---

# Principles Shipping Gate

## Overview

A pre-merge / pre-completion gate for the code-quality principles linters cannot see: **SOLID, YAGNI, typing discipline, build/test/lint verification, project-standards conformance, named anti-patterns**. One reviewer, one pass, findings in a strict two-axis contract that resists severity gaming.

## When to use

- A PR is being prepared
- Completion is being claimed on a non-trivial code change
- A refactor is being declared done

**Self-skip on:** docs-only diffs, config-only diffs (unless config affects build/test/lint), trivial typos, generated-code-only diffs.

## When NOT to use

- Bug-finding → `code-review`
- Auto-fix refactoring → `simplify`
- Architecture conformance to a style (hexagonal/clean/DDD) — needs whole-graph context this gate does not have

## The gate

Dispatch **one fresh-context reviewer** (or run the pass yourself if reviewer dispatch is unavailable) over the diff plus its immediate dependencies, checking this fixed list — every item, every time, in order, with an explicit verdict per item:

| # | Principle | Blocking? |
|---|---|---|
| 1 | SRP — units doing more than one thing | yes |
| 2 | OCP — type-switching that should be polymorphism or a type-checked extension point | yes |
| 3 | LSP — subtypes violating the parent's documented contract | yes |
| 4 | YAGNI — code paths, classes, flags with no current consumer | yes |
| 5 | Typing — untyped public surfaces, `any` leaks, missing return types | yes |
| 6 | Verification — run the project's build/test/lint (defer to `superpowers:verification-before-completion` if loaded) and gate on green | yes |
| 7 | Project standards — read the declared conventions (CLAUDE.md, README, `.editorconfig`, linter config) and check each | yes |
| 8 | ISP — interfaces forcing consumers to depend on methods they don't use; DIP — high-level modules constructing concrete low-level classes | advisory |
| 9 | Named anti-patterns — god class (>500 LOC or >15 public methods), primitive obsession (≥3 raw primitives in domain logic where a named type fits), feature envy, anemic domain, shotgun surgery (>5 files for one concept) | advisory |

The per-item verdict list is the coverage mechanism: an item without a verdict line means the gate did not run.

### Violation/concern contract

```
VIOLATION (blocks ONLY from a blocking row):
  - file:line cited
  - concrete failure scenario reproducible from current code
  - named rule
CONCERN (advisory always):
  - code smell without a concrete reproducible failure
```

≤3 findings per principle. **Block iff `row = blocking AND type = violation`.** Advisory rows never block; concerns never block. This two-axis rule closes severity-label gaming in both directions.

### Report

```
PRINCIPLES GATE: BLOCKED | CLEAR (advisory: N concerns)
Per-principle verdicts: 1 ✓/✗ … 9 ✓/✗
Blocking violations: [<principle>] <file:line> — <scenario> (<rule>)
Verification: pass | fail | deferred
```

BLOCKED → do not merge or claim completion; fix and re-run.

### Large-diff escalation (unvalidated)

For diffs over **400 changed lines or 10 files**, you MAY decompose into parallel per-principle reviewers (one per blocking row, same contract, same budgets, aggregate by the two-axis rule). This escalation is **not yet validated** — at ordinary diff sizes one reviewer measures equal to a full per-principle roster, so decompose only when the diff genuinely exceeds one reviewer's attention.

## Rationalizations to refuse

| Excuse | Reality |
|---|---|
| "I'll skip verification because CI will catch it" | This gate confirms green BEFORE the completion claim; CI-after-claim is the failure it closes |
| "This finding is *almost* a violation, block anyway" | No concrete reproducible scenario → concern. Don't game the boundary |
| "Advisory row found something serious, promote it" | Advisory never blocks. Cite it in the report; the human decides |
| "Small diff, I'll skim my favorite principles" | The per-item verdict list is mandatory; a skipped row = gate did not run |
