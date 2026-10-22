#lang racket/base

;; Offline walkthrough: recover a small polynomial from data by symbolic
;; regression. Seeded, deterministic, no dependencies — this is the same
;; run CI performs in the quality job.

(require graft)

(random-seed 2026)

(define target (lambda (x) (+ (* x x) x 1)))

(define dataset
  (for/list ([x (in-list '(#i-5 #i-4 #i-3 #i-2 #i-1 #i0 #i1 #i2 #i3 #i4 #i5))])
    (cons (hash 'x x) (target x))))

(define result
  (evolve dataset #:generations 60 #:population-size 300))

(printf "target:       x^2 + x + 1\n")
(printf "found:        ~s\n" (outcome-best-tree result))
(printf "mean |error|: ~a\n"
        (real->decimal-string (outcome-best-error result) 4))
