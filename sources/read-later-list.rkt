#lang racket

(require "../audrey3/utils.rkt")
(require srfi/19)
(require db)

(provide ReadLaterListSource)

(define (ReadLaterListSource date-format local-source db)
  (lambda (filter [force-refresh? #f])
    (let* ([dates (read-later-days date-format db)]
           [sorted (sort dates time<=?)])
      (map
        (lambda (date)
          (let* ([pretty (date->string date date-format)]
                 [label (string-append "read-later:" pretty)])
            `(("title" . ,pretty)
              ("action-ui-eval" .
               (open-feed '(and (source ,local-source)
                                (has-label? ,label)))))))
        sorted))))

(define (read-later-days date-format db)
  (filter-labels->timestamps
    date-format
    (map
      (curryr substring (string-length "read-later:"))
      (query-list
        db "SELECT DISTINCT label FROM label_pairs
            WHERE label LIKE 'read-later:%'"))))

(define (filter-labels->timestamps date-format labels)
  (cond
    [(null? labels) '()]
    [else (append (with-handlers ([exn:fail? (lambda (e) '())])
                    `(,(string->date (car labels) date-format)))
                  (filter-labels->timestamps date-format (cdr labels)))]))
