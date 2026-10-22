# Graft

**Genetic programming for Racket — programs as S-expressions, bred by subtree surgery.**

[![CI](https://github.com/turinglambdaai/graft/actions/workflows/ci.yml/badge.svg)](https://github.com/turinglambdaai/graft/actions/workflows/ci.yml) ![Racket](https://img.shields.io/badge/Racket-9F1D20?logo=racket&logoColor=white) [![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)

**English** · [中文](README.zh-CN.md)

Graft breeds executable Racket forms with genetic programming. An individual is an ordinary S-expression: numbers and variable symbols at the leaves, function applications at the branches. Because code is data, crossover and mutation are operations on list structure — no interpreter trees, no virtual machines — and evaluation is one recursive walk.

The default fitness drives symbolic regression: hand it a dataset of environment/target pairs and it evolves the formula. Graft is not a machine-learning framework; it is one loop, honest about its knobs, with depth-capped trees that stay small by construction.

## Quick start

```racket
(require graft)

(random-seed 2026)                      ; determinism is the caller's choice

(define dataset
  (for/list ([x (in-list '(#i-5 #i-4 #i-3 #i-2 #i-1 #i0 #i1 #i2 #i3 #i4 #i5))])
    (cons (hash 'x x) (+ (* x x) x 1))))

(define result (evolve dataset #:generations 60 #:population-size 300))

(outcome-best-tree result)   ; something shaped like (+ x (+ (* x x) 1))
(outcome-best-error result)  ; mean absolute error over the dataset
```

A runnable walkthrough lives in `examples/symbolic-regression.rkt` and runs in CI.

## Design notes

- **Bloat is bounded by construction.** Crossover children that would exceed the depth cap fall back to their parents; mutated growth is budgeted against the remaining depth. A run cannot breed unbounded trees.
- **Failures are fitness, not crashes.** The default function set includes `pdiv`, division guarded against zero divisors — search wanders through them constantly.
- **Every knob is a parameter.** Function registry, variables, constant range, depth cap, population, tournament size, rates, elitism — all `parameterize`-scoped, nothing global to reset.
- **Determinism belongs to the caller.** Graft never seeds the generator; `(random-seed n)` before `evolve` makes a run exactly reproducible.

## Development

```sh
raco pkg install --auto --name graft .
raco test -p graft
raco setup --check-pkg-deps graft
racket examples/symbolic-regression.rkt
```

CI runs the test suite on Linux, Windows, and macOS against Racket 9.0 and 9.3, then checks declared dependencies, builds the reference manual, and runs the seeded walkthrough.

## License

[Apache-2.0](LICENSE)
