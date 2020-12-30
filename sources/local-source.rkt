#lang racket

(require "../audrey3/local-db.rkt")
(require "../audrey3/utils.rkt")
(require db)

(provide LocalDBSource)

(define (LocalDBSource db)
  (lambda (filters [force-refresh #f])
    (map destrify
         (query-list
           db "SELECT racket_code FROM local_items"))))
