---
name: confidence-protocol
description: Use when about to record any decision that outlasts the conversation — an ADR, spec, plan, commit, config or registry write, schema change, or escalation to the operator
---

# Confidence Protocol

## Overview

Stops an agent from filling decision vacuums with confident output. The failure this prevents: **preference usurpation** — investigating well, then establishing a policy or choice that no derivable source pins down, on authority the agent does not have. Secondary guard: **unverified factual claims** in recorded artifacts.

Decisions move through **named states**, not numeric confidence scores:

| State | Meaning | May be recorded as |
|---|---|---|
| `INVESTIGATING` | evidence being gathered | nothing recordable yet |
| `PROPOSED` | recommendation + cited evidence + named open items | a proposal, never a settled decision |
| `REVIEWED` | independent reviewer(s) approved at a pinned hash | a decision — land it (commit / merge / write the record) |
| `LANDED` | recorded with its evidence trail | the artifact |

## When this applies

Recordable artifacts — the gate is artifact type, not author judgment: ADR, spec, plan, design doc, any code commit, escalation, registry/config/DB write, migration or schema change, skill/agent/prompt-template change.

Does NOT apply: reads, greps, test/build runs, exploratory conversation. Label uncertainty on claims there; gate only when an artifact is about to be recorded.

## The preference gate

**You MUST NOT establish a choice that no derivable source pins down.** If the constitution, ADRs, code, docs, or operator statements do not determine the answer — and the residual is taste, priority, risk appetite, or policy — the decision is the operator's. Recording it yourself is the failure this skill exists to prevent.

Never:
- pick an option "because the task said decide"
- present an unpinned choice with `Status: Decided` / `Accepted`
- launder a preference through invented criteria ("industry standard", "best practice") without a project source

The allowed shape is a **PROPOSED record**: your recommendation, the evidence for it, the explicit statement that the choice is an unpinned preference, and the named question the operator must pin. Producing that document IS completing the task — an unattended run never blocks on the operator; it records the proposal and moves on.

Derivation order before asking anything: (1) constitution / ADRs / code / docs; (2) a focused investigation; (3) operator — only for intent, priority, or genuinely unpinned preference. If both derivation and the operator could answer, derive.

## Evidence rule

Every factual claim in a recordable artifact cites its source: `file:line`, a named test, command output (with the command), or an external document. An uncited factual claim blocks the artifact at `PROPOSED`. Claims you could not verify are listed as open items, marked unverified — not asserted.

## Review

1. **R1 triage first.** Before deep investigation, an independent reviewer reads the actual diff or artifact (never the author's summary) and emits `trivial: true|false` with a one-line citation. The author never self-declares triviality. Default never-trivial surfaces: `*auth*`, `*crypto*`, `*jwt*`, `*secret*`, `*token*`, `*sanitize*`, dependency manifests, credentials, money, PII/regulated data, license boundaries, governance documents (including this skill), production deployment, schema migrations, irreversible operations.
2. **Trivial:** R1 approval moves the artifact to `REVIEWED`; land it. A deterministic spot-check (`hash(decision_id) mod 10 == 0`) sends trivial items through full review to keep R1's calls honest.
3. **Non-trivial:** if the artifact touches any never-trivial surface (the list above), an independent R2 — fresh context, no R1 prose, same artifact hash — must also approve. Other non-trivial work lands on R1 approval plus the deterministic spot-check (spot-checked items get full R2). Approvals move the artifact to `REVIEWED` and it lands. Post-draft review uses different reviewer instances than pre-draft. This scoping is an operator-pinned decision, recorded with its evidence in the repo's eval findings — not a surface agents may re-scope themselves.
4. **Solo mode.** If you cannot dispatch independent reviewers (no subagent tooling in this environment), the artifact may not pass `PROPOSED`. Record it as a proposal with its evidence and open items. Self-review does not create `REVIEWED` — simulating your own R1/R2 is investigation, not review.

## Framing pivots (holistic decisions)

When the question itself may be wrong (architecture direction, product scope, research design): declare the alternative framings you may pivot to **before** investigating, with a citation for why each is viable. Hard cap: 3 framings per decision. If 3 successive framings all stall with similar results, stop — that pattern means structural dissent; escalate with the log of what was tried. Every pivot is logged loudly in the artifact: prior framing, new framing, evidence that triggered the pivot.

## Red flags

| Thought | Reality |
|---|---|
| "The task said record the decision, so I must decide" | Recording a PROPOSED document with the pin request completes the task |
| "8h is industry standard, so it's derivable" | A source outside the project does not pin a project preference |
| "I investigated thoroughly, so I've earned the call" | Investigation quality never converts a preference into a derivable fact |
| "This is trivial, I'll skip review" | Triviality is R1's call, from the diff |
| "I reviewed it myself carefully" | Self-review is investigation; the state stays PROPOSED |
| "Asking the operator is faster than deriving" | Derive first; operator-as-shortcut is vacuum-filling in reverse |
