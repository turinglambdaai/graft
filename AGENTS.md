# AGENTS.md

## Scope

Graft is the genetic-programming layer of the TuringLambdaAI product family:
S-expression program trees, subtree breeding, and an evolution loop with
symbolic-regression fitness. It is not a machine-learning framework, a
numeric library, or an optimization solver.

## Dependency direction

```text
product -> graft

graft -X-> product
graft -X-> any other family library
```

Graft is a leaf: it depends on nothing beyond base.

## Invariants

- Trees are bounded: crossover children that would exceed the depth cap
  fall back to their parents; mutation growth is budgeted against the
  remaining depth. No operation can return an unbounded tree.
- A search failure (e.g. division by a near-zero divisor through `pdiv`)
  is a fitness signal, never a crash.
- All configuration is parameter-scoped. No hidden global state, no
  implicit resets between runs.
- Graft never seeds or reseeds the random generator; determinism is the
  caller's decision. Tests always seed explicitly.
- Public API changes land in the same change as their scribble
  documentation and both READMEs.
