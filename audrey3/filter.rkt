#lang racket

(require "local-db.rkt"
         "feed-item.rkt"
         "utils.rkt"
         racket/date)

(provide check-filter)

(define (check-filter filter item db)
  (match filter
         [`(or) #f]
         [`(or ,clause ,others ...)
           (if (check-filter clause item db)
               #t
               (check-filter (cons 'or others) item db))]
         [`(and) #t]
         [`(and ,clause ,others ...)
           (if (not (check-filter clause item db))
               #f
               (check-filter (cons 'and others) item db))]
         [`(not ,filter) (not (check-filter filter item db))]
         [`(if ,cond ,then ,else)
           (if (check-filter cond item db)
               (check-filter then item db)
               (check-filter else item db))]
         [`(,op ,A ,B)
           (let ([A (eval-filter A item)]
                 [B (eval-filter B item)]
                 [op-fn (op->fn op)])
             (op-fn A B))]
         [`(has-attr ,attr)
           (feed-item->has-attr? item (eval-filter attr item))]
         [`(has-label? ,label)
           (let ([label (eval-filter label item)])
             (has-label? item label db))]
         ['#t #t]
         ['#f #f]
         [_ (displayln filter) (error "Syntax error in the filter")]))

(define (op->fn op)
  (match op
         ['= equal?]
         ['< <]
         ['> >]
         ['<= <=]
         ['>= >=]))

(define (eval-filter expr item)
  (match expr
         [`(attr ,key)
           (feed-item->attr-value item (eval-filter key item))]
         [`(now) (current-seconds)]
         ; Using (today) allows you to cache things for longer than (now).
         ; Alternatively, maybe web-cache should index on something other than
         ; the raw URL.
         [`(today) (date->seconds
                     (struct-copy date (current-date)
                                  [second 0] [hour 0] [minute 0]))]
         [`(- ,a ,b) (- (eval-filter a item) (eval-filter b item))]
         [`(days ,n) (* (* 60 60 24) (eval-filter n item))]
         [_ expr]))
