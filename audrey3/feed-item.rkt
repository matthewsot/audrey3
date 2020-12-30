#lang racket

(require "lview.rkt")
(require racket/serialize)

(provide feed-item->ids
         feed-item->id
         feed-item->meta-id
         feed-item->attr-value
         feed-item->has-attr?
         feed-item-title
         feed-item->primary-id
         feed-item->pager-lines)

; An item is just an association list of attributes (keys should be strings).

(define (feed-item-title item)
  (feed-item->attr-value item "title"))

(define valid-id (disjoin string? number?))

(define (feed-item->ids item)
  (filter (compose valid-id cdr) item))

(define (feed-item->meta-id item)
  (format "~s"
          (sort (feed-item->ids item) (compose string<? car))))

(define (feed-item->id item key)
  (let ([id (feed-item->attr-value item key)])
    (if (valid-id id) id (error "Bad ID"))))

(define (feed-item->primary-id item)
  (cdar (feed-item->ids item)))

(define (feed-item->has-attr? item key)
  (not (eqv? #f (assoc key item))))

(define (feed-item->attr-value item key)
  (cdr (assoc key item)))

(define (feed-item->pager-lines item cols)
  (pagerify
    (string-append
      (~a (feed-item-title item)
          #:align 'center
          #:width cols
          #:pad-string "~"
          #:limit-marker "[...]")
      "\n"
      (foldl string-append
             ""
             (map (lambda (attr-pair) (string-append (~a attr-pair) "\n"))
                  item)))
    cols))

(define (pagerify text cols)
  (pager-wrap (string-split text "\n") cols))

(define (pager-wrap lines cols)
  (cond
    [(null? lines) '()]
    [(<= (string-length (car lines)) cols)
     `(,(car lines) . ,(pager-wrap (cdr lines) cols))]
    [else
     (cons (substring (car lines) 0 cols)
           (pager-wrap `(,(substring (car lines) cols) . ,(cdr lines))
                       cols))]))
