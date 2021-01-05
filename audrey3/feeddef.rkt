#lang racket

; For check-filter in feeddef->sources.
(require "filter.rkt")
(provide register-sources
         register-source
         feeddef->sources)

(define SOURCES (make-hash))
(define (register-source name source) (hash-set! SOURCES name source))
(define-syntax register-sources
  (syntax-rules ()
    [(register-sources) (void)]
    [(register-sources [name source] r ...)
     (begin (register-source name source)
            (register-sources r ...))]))

(define (feeddef->sources expr db)
  (hash-map
    (feeddef->source-dnf expr)
    (lambda (source fltr)
      (lambda ([force-refresh #f])
        (map (curryr cons fltr)
          (filter (lambda (item) (check-filter fltr item db))
                  (source fltr force-refresh)))))))

; NOTE: This just expands at most one top-level macro, it doesn't recurse.
(define (expand-macros expr)
  (match expr
         [`(sources ,sources ...)
           `(or . ,(map (lambda (s) `(source ,s)) sources))]
         [`(if ,cond ,then ,else)
           `(or (and ,cond ,then) (and (not ,cond) ,else))]
         [`(in ,value (,options ...))
           `(or . ,(map (lambda (option) `(= ,value ,option)) options))]
         [_ expr]))

; Given a feeddef, returns a hashmap of source -> filter.
(define (feeddef->source-dnf expr)
  (match (expand-macros expr)
         [`(or) (make-hash '())]
         [`(or ,clause ,others ...)
           (join (feeddef->source-dnf clause)
                 (feeddef->source-dnf (cons 'or others)))]
         [`(and) (make-hash '((_ . #t)))]
         [`(and ,clause ,others ...)
           (meet (feeddef->source-dnf clause)
                 (feeddef->source-dnf (cons 'and others)))]
         [`(not ,subexpr) (negate (feeddef->source-dnf subexpr))]
         [`(source ,source-expr)
           (make-hash `((,(eval-source-expr source-expr) . #t)))]
         [_ (make-hash `((_ . ,expr)))]))

(define (eval-source-expr expr)
  (cond
    [(procedure? expr) expr]
    [(symbol? expr) (hash-ref SOURCES expr)]
    [else (error "Invalid source.")]))

(define (join A B)
  (hash-for-each
    A
    (lambda (source existing-A)
      (cond
        [(hash-has-key? B source)
         (hash-set! B source `(or ,existing-A ,(hash-ref B source)))]
        [else (hash-set! B source existing-A)])))
  B)

(define (meet A B)
  (hash-for-each
    A
    (lambda (source existing-A)
      (cond
        [(hash-has-key? B source)
         (hash-set! B source `(and ,existing-A ,(hash-ref B source)))]
        [(hash-has-key? B '_)
         (hash-set! B source `(and ,existing-A ,(hash-ref B '_)))])))
  (cond [(not (and (hash-has-key? A '_) (hash-has-key? B '_)))
         (hash-remove! B '_)])
  B)

; TODO: Negate shouldn't work for things with multiple sources, or something
; like that...
(define (negate A)
  (for ([pair (hash->list A)])
    (let* ([source (car pair)]
           [filter (cdr pair)])
      (hash-set! A source `(not ,filter))))
  A)
