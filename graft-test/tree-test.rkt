#lang racket/base

(require racket/hash
         rackunit
         graft)

(define (env . pairs) (apply hash pairs))

(test-case "evaluation walks the tree"
  (check-equal? (eval-tree 5 (env)) 5)
  (check-equal? (eval-tree 'x (env 'x 3)) 3)
  (check-equal? (eval-tree '(+ x 4) (env 'x 3)) 7)
  (check-equal? (eval-tree '(* x (+ x 1)) (env 'x 3)) 12))

(test-case "protected division survives zero divisors"
  (check-equal? (eval-tree '(pdiv x x) (env 'x 0)) 1.0)
  (check-equal? (eval-tree '(pdiv 6 x) (env 'x 2)) 3))

(test-case "unknown leaves and arities fail loudly"
  (check-exn exn:fail:contract? (lambda () (eval-tree 'y (env 'x 1))))
  (check-exn exn:fail:contract? (lambda () (eval-tree '(+ x) (env 'x 1))))
  (check-exn exn:fail:contract? (lambda () (eval-tree '(pow x 2) (env 'x 1)))))

(test-case "size and depth"
  (check-equal? (tree-size 5) 1)
  (check-equal? (tree-size '(+ x 1)) 3)
  (check-equal? (tree-depth 5) 0)
  (check-equal? (tree-depth '(* x (+ x 1))) 2))

(test-case "random trees are valid and respect the depth cap"
  (random-seed 42)
  (for ([_ (in-range 300)])
    (define t (random-tree (current-max-depth)))
    (check-true (<= (tree-depth t) (current-max-depth)))
    ;; evaluation over every variable binding is the validity proof
    (check-true (real? (eval-tree t (env 'x 1.5))))))

(test-case "configuration knobs are honored"
  (parameterize ([current-variables '(a b)]
                 [current-functions (hash 'neg (list 1 -))]
                 [current-max-depth 3])
    (random-seed 7)
    (define t (random-tree 2))
    (check-true (real? (eval-tree t (env 'a 2 'b 3))))))

(test-case "crossover returns valid children within the depth cap"
  (random-seed 11)
  (for ([_ (in-range 100)])
    (define-values (a b) (crossover (random-tree 4) (random-tree 4)))
    (check-true (<= (tree-depth a) (current-max-depth)))
    (check-true (<= (tree-depth b) (current-max-depth)))
    (check-true (real? (eval-tree a (env 'x 2))))
    (check-true (real? (eval-tree b (env 'x 2))))))

(test-case "mutation changes something, sometimes"
  (random-seed 3)
  (define base (random-tree 4))
  (check-true
   (for/or ([_ (in-range 20)])
     (not (equal? base (mutate base))))))

(test-case "replace-subtree hits exactly the addressed node"
  (define t '(+ x (* x x)))
  ;; path () replaces the whole tree
  (check-equal? (replace-subtree t '() 7) 7)
  ;; path (1) replaces the second child of the root
  (check-equal? (replace-subtree t '(1) 'y) '(+ x y))
  ;; path (1 0) replaces the leaf inside that child
  (check-equal? (replace-subtree t '(1 0) 5) '(+ x (* 5 x))))
