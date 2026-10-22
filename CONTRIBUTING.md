# Contributing

## Development loop

```sh
raco pkg install --auto --name graft .
raco test -p graft
raco setup --check-pkg-deps graft
raco scribble --htmls --dest /tmp/graft-doc graft-doc/scribblings/graft.scrbl
racket examples/symbolic-regression.rkt
```

CI must be green on `main`; whoever pushes a red `main` fixes or reverts on the spot.

## Rules

- Read `AGENTS.md` before changing code; the invariants there are normative.
- Tests seed the generator explicitly; no test depends on unseeded randomness.
- Public API changes land in the same change as their scribble documentation and both READMEs.
