#lang racket

(require "../audrey3/feed-item.rkt")
(provide print-webpage)

(define (print-webpage item)
  (cond
    [(feed-item->has-attr? item "url")
     (system* (find-executable-path "wkhtmltopdf")
              "--log-level" "none"
              "--disable-javascript"
              (feed-item->attr-value item "url")
              "private/printed.pdf")
     #t]
    [else #f]))
