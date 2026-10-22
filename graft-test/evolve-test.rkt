#lang racket/base

(require racket/list
         rackunit
         graft)

(define (make-dataset f xs)
  (for/list ([x (in-list xs)])
    (cons (hash 'x x) (f x))))

(define xs (for/list ([i (in-range -10 11)]) (* 1.0 i)))

(test-case "fitness is zero for the exact tree, positive otherwise"
  (define dataset (make-dataset (lambda (x) (+ (* x x) x 1)) xs))
  (check-equal? (regression-fitness '(+ x (+ (* x x) 1)) dataset) 0.0)
  (check-true (> (regression-fitness 'x dataset) 1.0)))

(test-case "a tiny seeded run improves on its first generation"
  (random-seed 123)
  (define dataset (make-dataset (lambda (x) (+ (* x x) x 1)) xs))
  (parameterize ([current-population-size 40]
                 [current-elitism 2])
    (define result (evolve dataset #:generations 30))
    ;; elitism makes the best monotonically non-worsening, so the outcome
    ;; must beat a trivial constant tree on this seeded run
    (check-true (< (outcome-best-error result)
                   (regression-fitness '(* 1 1) dataset)))
    (check-equal? (outcome-generation result) 30)))

(test-case "evolution respects configured knobs"
  (random-seed 5)
  (define dataset (make-dataset (lambda (x) (* 2 x)) xs))
  (parameterize ([current-population-size 12]
                 [current-elitism 1]
                 [current-max-depth 4])
    (define result (evolve dataset #:generations 3))
    (check-true (<= (tree-depth (outcome-best-tree result))
                    (current-max-depth)))
    ;; a perfect multiplier is reachable fast for a linear target
    (check-true (< (outcome-best-error result) 1.0))))

(test-case "degenerate inputs fail loudly"
  (check-exn exn:fail:contract?
             (lambda () (regression-fitness 'x '())))
  (check-exn exn:fail:contract?
             (lambda () (evolve (make-dataset (lambda (x) x) xs) #:generations 0))))
