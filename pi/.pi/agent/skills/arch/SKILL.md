---
name: arch
description: Architect Mode — design solutions without implementing them. Output concrete, implementable plans (types, function signatures, call graph) with no room for doubt. Use when asked to architect, plan, design, or scope a feature without writing code.
disable-model-invocation: true
---

# Architect Mode

Architect the solution. Don't implement. Output concrete, implementable plan. No room for doubt.

## 1. Clarify First

- State assumptions.
- Multiple reasonable interpretations? Present as options. Never pick silently.
- Doubt, ambiguity, missing context, tradeoff user should weigh? Surface in plain language. Ask before proceeding.
- No silent decision making. Flag every fork in road.

## 2. Think in Types

- Design around type system. Model domain first.
- Define every type before any function. Invalid states unrepresentable via types. Tagged unions for alternatives, product types for co-occurring data. No primitive obsession. Wrap domain concepts.
- Errors as values (Result/Either), not null/throws. No null/undefined returns.
- State module boundaries. What each module owns.

## 3. Function Signatures First

- Per function: name, params with types, return type, one-line responsibility.
- Pure by default. Side effects at outermost boundary.
- Compose, don't chain imperatives. One thing per function. No mutation. Declarative over imperative.

## 4. Minimal Complexity

Least code that satisfies requirement. Nothing speculative.

- No features beyond request. No single-use abstractions. No unasked flexibility. No new dependency if avoidable.
- Std lib? Use it. Installed dep? Use it. Boring over clever. Fewest files.

## 5. Output

Concrete, implementable plan:

1. **Assumptions & Open Questions** — stated, or resolved with user.
2. **Modules & ownership** — created vs modified.
3. **Types** — every type/model introduced.
4. **Function signatures** — each with types and one-line contract.
5. **Call graph** — production flow and, if different, tests flow, in call-graph format (plain text, indented → arrows, ts code block).
6. **Verification** — one runnable assertion-based check per non-trivial logic. No frameworks.
7. **YAGNI notes** — what is NOT built and why.

## 6. Confirm Call Graph

Before finalizing, present call graph. Confirm with user. Ask: every edge intended? Anything missing? Don't proceed until user seen and accepted graph. When showing call graphs, execution flows, or architecture traces, use this format:

Production:

```
HTTP handlers
  → ComponentA
    → ComponentA.layerX
      → ComponentB
        → ComponentC
```

Tests:

```
HTTP handlers
  → ComponentA
    → componentMemoryLayer
      → ComponentA.layer
        → ComponentB.layerMemory
```

- Plain text only, no rendered diagrams
- Indented → arrows for hierarchy
- ts code block
- Production and Tests as separate sections when they differ
- Include call graphs in project overviews, architecture summaries, code explanations

## 7. Leave No Room for Doubt

Reader must implement from plan alone. No gaps, no "detail left to taste". If something can't be decided here, it's an open question, not silent default.

Order: clarify doubts, then types, then signatures, then call graph, confirm graph with user last.
