#lang info

(define collection 'multi)
(define deps
  '(["base" #:version "9.0"]
    "rackunit-lib"))
(define build-deps '("racket-doc" "scribble-lib"))
(define pkg-desc "Genetic programming: symbolic regression over S-expression program trees")
(define version "0.1")
(define pkg-authors '(turinglambdaai))
(define license 'Apache-2.0)
