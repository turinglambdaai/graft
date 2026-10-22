#lang racket/base

;; Program trees. An individual is an ordinary S-expression: a number or a
;; variable symbol at the leaves, a function application at the branches.
;; Code-as-data is the whole trick — crossover and mutation operate on the
;; list structure directly, and evaluation is one recursive walk.

(require racket/list
         racket/math
         racket/random)

(provide current-functions
         current-variables
         current-constant-range
         current-max-depth
         eval-tree
         tree-size
         tree-depth
         random-tree
         random-subtree-path
         replace-subtree
         crossover
         mutate)

;; name -> (list arity procedure). pdiv is division guarded against zero
;; divisors: GP search wanders through them constantly, and a crash is not
;; a fitness signal.
(define current-functions
  (make-parameter
   (hash '+ (list 2 +)
         '- (list 2 -)
         '* (list 2 *)
         'pdiv (list 2 (lambda (a b) (if (< (abs b) 1e-12) 1.0 (/ a b)))))))

(define current-variables (make-parameter '(x)))

(define current-constant-range (make-parameter (cons -5 5)))

;; Depth cap for freshly grown material. Without it, crossover can breed
;; trees that double in size every generation.
(define current-max-depth (make-parameter 6))

(define (checked-tree tree)
  (cond
    [(number? tree) tree]
    [(symbol? tree)
     (unless (member tree (current-variables))
       (raise-argument-error 'eval-tree
                             (format "variable in ~a" (current-variables))
                             tree))
     tree]
    [(pair? tree)
     (define entry (hash-ref (current-functions) (car tree) #f))
     (unless entry
       (raise-argument-error 'eval-tree
                             (format "function in ~a" (hash-keys (current-functions)))
                             (car tree)))
     (define arity (car entry))
     (define args (cdr tree))
     (unless (= (length args) arity)
       (raise-argument-error 'eval-tree
                             (format "~a of exactly ~a arguments" (car tree) arity)
                             tree))
     (for/list ([arg (in-list args)]) (checked-tree arg))
     tree]
    [else (raise-argument-error 'eval-tree "(or/c number? symbol? pair?)" tree)]))

;; env is a hash of variable symbol -> number.
(define (eval-tree tree env)
  (cond
    [(number? tree) tree]
    [(symbol? tree)
     (hash-ref env tree
               (lambda ()
                 (raise-argument-error 'eval-tree
                                       (format "binding for ~a" tree)
                                       env)))]
    [else
     (define entry
       (hash-ref (current-functions) (car tree)
                 (lambda ()
                   (raise-argument-error 'eval-tree
                                         (format "function in ~a"
                                                 (hash-keys (current-functions)))
                                         (car tree)))))
     (define args (cdr tree))
     (unless (= (length args) (car entry))
       (raise-argument-error 'eval-tree
                             (format "~a of exactly ~a arguments"
                                     (car tree) (car entry))
                             tree))
     (define proc (cadr entry))
     (apply proc (map (lambda (arg) (eval-tree arg env)) args))]))

(define (tree-size tree)
  (if (pair? tree)
      (add1 (for/sum ([arg (in-list (cdr tree))]) (tree-size arg)))
      1))

(define (tree-depth tree)
  (if (pair? tree)
      (add1 (for/fold ([d 0]) ([arg (in-list (cdr tree))])
              (max d (tree-depth arg))))
      0))

(define (random-leaf)
  (if (< (random) 0.5)
      (random-ref (current-variables))
      (random-between (current-constant-range))))

(define (random-between range)
  (define lo (car range))
  (define hi (cdr range))
  (+ lo (* (- hi lo) (random))))

;; Grow starts full-arity at the root but allows leaves early, which gives
;; irregular shapes; full builds a complete tree of exactly DEPTH. Every
;; branch respects max-depth even when grow gets lucky, so a deeper max
;; depth is the only way to grow bigger trees.
(define (random-tree depth #:method [method (random-ref '(grow full))])
  (unless (exact-positive-integer? depth)
    (raise-argument-error 'random-tree "exact-positive-integer?" depth))
  (unless (memq method '(grow full))
    (raise-argument-error 'random-tree "(or/c 'grow 'full)" method))
  (define (node remaining)
    (cond
      [(zero? remaining) (random-leaf)]
      [(and (eq? method 'grow) (< (random) 0.4)) (random-leaf)]
      [else
       (define name (random-ref (hash-keys (current-functions))))
       (define arity (car (hash-ref (current-functions) name)))
       (cons name (for/list ([_ (in-range arity)]) (node (sub1 remaining))))]))
  (node depth))

;; A path into the tree as a list of child indices from the root. The
;; index is drawn exactly once and reused for both the descent and the
;; recorded path — drawing twice would record a different node than the
;; one the traversal visited.
(define (random-subtree-path tree)
  (let loop ([node tree] [path '()])
    (cond
      [(or (not (pair? node)) (zero? (random 3))) (reverse path)]
      [else
       (define i (random (length (cdr node))))
       (loop (list-ref (cdr node) i) (cons i path))])))

(define (path->subtree tree path)
  (for/fold ([node tree]) ([i (in-list path)])
    (list-ref (cdr node) i)))

(define (replace-subtree tree path replacement)
  (cond
    [(null? path) replacement]
    [else
     (define i (car path))
     (cons (car tree)
           (for/list ([arg (in-list (cdr tree))]
                      [j (in-naturals)])
             (if (= j i)
                 (replace-subtree arg (cdr path) replacement)
                 arg)))]))

;; Subtree swap: both parents donate one subtree. A child that would exceed
;; the depth cap falls back to its parent unchanged — bloat is bounded by
;; construction, not by hope.
(define (crossover parent-a parent-b)
  (define path-a (random-subtree-path parent-a))
  (define path-b (random-subtree-path parent-b))
  (define child-a (replace-subtree parent-a path-a (path->subtree parent-b path-b)))
  (define child-b (replace-subtree parent-b path-b (path->subtree parent-a path-a)))
  (define limit (current-max-depth))
  (values (if (> (tree-depth child-a) limit) parent-a child-a)
          (if (> (tree-depth child-b) limit) parent-b child-b)))

(define (mutate tree)
  (define path (random-subtree-path tree))
  (define depth-budget
    (max 0 (- (current-max-depth) (length path))))
  (define replacement
    (if (zero? depth-budget)
        (random-leaf)
        (random-tree (min 2 depth-budget))))
  (replace-subtree tree path replacement))
