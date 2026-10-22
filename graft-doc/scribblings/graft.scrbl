#lang scribble/manual

@title{Graft}
@author{TuringLambdaAI}

Public module: @tt{graft}

Graft is genetic programming for Racket: individuals are ordinary
S-expression program trees, fitness is any function of a tree, and the
evolution loop breeds new trees by subtree crossover and mutation. The
default fitness drives symbolic regression — recover a formula from data —
but the tree representation is general.

@section{Program trees}

@verbatim{
(eval-tree tree env) -> real?
  tree : (or/c number? symbol? pair?)
  env  : (hash/c symbol? real?)
(tree-size tree) -> exact-nonnegative-integer?
(tree-depth tree) -> exact-nonnegative-integer?
}

A leaf is a number or a variable symbol; a branch applies a function from
the registry to its evaluated children. The default registry is @tt{+ - *}
and @tt{pdiv}, division guarded against zero divisors — a search that
wanders into a division by zero should pay a fitness price, not crash.

@section{Configuration}

@verbatim{
(current-functions)      : (hash/c symbol? (list/c exact-nonnegative-integer? procedure?))
(current-variables)      : (listof symbol?)          ; default '(x)
(current-constant-range) : (cons/c real? real?)      ; default '(-5 . 5)
(current-max-depth)      : exact-positive-integer?   ; default 6
}

Every knob is a parameter, so runs are scoped with @racket[parameterize].
@tt{current-max-depth} is the bloat guard: crossover children that would
exceed it fall back to their parents, and mutated growth is budgeted
against it. Depth caps hold by construction, not by hope.

@section{Growing and breeding}

@verbatim{
(random-tree depth #:method method) -> tree?
  method : (or/c 'grow 'full)
(crossover parent-a parent-b) -> (values tree? tree?)
(mutate tree) -> tree?
}

@tt{grow} allows early leaves (irregular shapes); @tt{full} builds
complete trees. Crossover swaps randomly chosen subtrees; mutation
replaces a random subtree with freshly grown material sized to the
remaining depth budget.

@section{The evolution loop}

@verbatim{
(evolve dataset
        #:generations n
        #:population-size size
        #:fitness fitness)
 -> outcome?
(outcome best-tree best-error generation) -> outcome?
(regression-fitness tree dataset) -> real?
  dataset : (listof (cons/c (hash/c symbol? real?) real?))
(make-population #:size size) -> (listof tree?)
}

The loop sorts by fitness, copies the elite unchanged, fills the rest by
tournament selection with crossover and mutation, and stops after
@tt{#:generations}. @tt{regression-fitness} is the mean absolute error
over a dataset of environment/target pairs.

Tuning knobs: @tt{current-population-size}, @tt{current-tournament-size},
@tt{current-crossover-rate}, @tt{current-mutation-rate},
@tt{current-elitism}.

@section{Determinism}

Nothing inside graft seeds or reseeds the random generator. A run is
reproducible exactly when the caller says so:

@racketblock[
(random-seed 2026)
(evolve dataset #:generations 60)
]
