#lang racket

(require "../audrey3/feed-item.rkt"
         racket/port)
(provide print-webpage)

(define (print-webpage item)
  (cond
    [(feed-item->has-attr? item "url")
     (parameterize ([current-output-port (open-output-nowhere)]
                    [current-error-port (open-output-nowhere)])
       (system* (find-executable-path "wkhtmltopdf")
                "--log-level" "none"
                "--disable-javascript"
                (feed-item->attr-value item "url")
                "private/printed.pdf"))]
    [else #f]))
