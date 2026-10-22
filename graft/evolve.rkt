#lang racket/base

;; The evolution loop. Determinism belongs to the caller: (random-seed n)
;; before evolve makes a run reproducible, which is what tests and
;; examples rely on.

(require racket/list
         racket/math
         racket/random
         "tree.rkt")

(provide (struct-out outcome)
         current-population-size
         current-tournament-size
         current-crossover-rate
         current-mutation-rate
         current-elitism
         regression-fitness
         make-population
         evolve)

(struct outcome (best-tree best-error generation) #:transparent)

(define current-population-size (make-parameter 200))

;; Tournament selection pressure. Small tournaments keep diversity; large
;; ones converge fast and prematurely.
(define current-tournament-size (make-parameter 5))

(define current-crossover-rate (make-parameter 0.9))

(define current-mutation-rate (make-parameter 0.15))

;; Number of best individuals copied unchanged into the next generation.
(define current-elitism (make-parameter 2))

;; DATASET is a list of (cons env target) where env is a hash of variable
;; -> number. Lower is better; the error is the mean absolute deviation.
(define (regression-fitness tree dataset)
  (unless (pair? dataset)
    (raise-argument-error 'regression-fitness "nonempty dataset" dataset))
  (define total
    (for/sum ([case (in-list dataset)])
      (abs (- (eval-tree tree (car case)) (cdr case)))))
  (/ total (length dataset)))

;; Ramped half-and-half: half the initial population grow, half full, with
;; depths spread across the range — the standard hedge against starting
;; from a monoculture of shapes.
(define (make-population #:size [size (current-population-size)])
  (for/list ([i (in-range size)])
    (define depth (add1 (modulo i (sub1 (current-max-depth)))))
    (random-tree depth #:method (if (even? i) 'grow 'full))))

(define (tournament population fitness-of)
  (define size (current-tournament-size))
  (define contenders
    (for/list ([_ (in-range size)])
      (random-ref population)))
  (argmin fitness-of contenders))

;; Fill the remaining slots exactly: a round adds one or two individuals,
;; and "until the length equals the target" can jump over the target and
;; then spin forever on a near miss. Budgeting the exact number needed
;; makes termination structural, not lucky.
(define (breed-aux acc needed parents fitness-of)
  (cond
    [(<= needed 0) acc]
    [else
     (define p1 (tournament parents fitness-of))
     (define p2 (tournament parents fitness-of))
     (define kids
       (if (< (random) (current-crossover-rate))
           (let-values ([(a b) (crossover p1 p2)]) (list a b))
           (list p1)))
     (define mutated
       (for/list ([kid (in-list kids)])
         (if (< (random) (current-mutation-rate))
             (mutate kid)
             kid)))
     (define taken (take mutated (min needed (length mutated))))
     (breed-aux (append acc taken) (- needed (length taken)) parents fitness-of)]))

(define (evolve dataset
                #:generations [generations 40]
                #:population-size [population-size (current-population-size)]
                #:fitness [fitness regression-fitness])
  (parameterize ([current-population-size population-size])
    (unless (exact-positive-integer? generations)
      (raise-argument-error 'evolve "exact-positive-integer?" generations))
    (define fitness-of (lambda (tree) (fitness tree dataset)))
    (define population (make-population))
    (let loop ([pop population] [gen 0])
      (define scored
        (sort (map (lambda (tree) (cons tree (fitness-of tree))) pop)
              < #:key cdr))
      (define best (car scored))
      (cond
        [(>= gen generations) (outcome (car best) (cdr best) gen)]
        [else
         (define elite-count (min (current-elitism) (length scored)))
         (define elites (map car (take scored elite-count)))
         (define parents (map car scored))
         (define children
           (breed-aux elites
                      (- population-size (length elites))
                      parents
                      fitness-of))
         (loop children (add1 gen))]))))
