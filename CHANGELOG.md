# Changelog

## 0.1.0 — 2026-10-22

- S-expression program trees with one-walk evaluation and a guarded default function set (`+ - * pdiv`).
- Parameter-scoped configuration: function registry, variables, constant range, depth cap.
- Subtree crossover with depth-cap fallback, budgeted mutation, ramped half-and-half init.
- Tournament evolution loop with elitism; symbolic regression fitness over env/target datasets.
- Caller-owned determinism: graft never seeds the random generator.
