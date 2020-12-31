#lang racket

(require "../audrey3/utils.rkt")
(require db)

(provide ReadLaterListSource)

(define (ReadLaterListSource local-source db)
  (lambda (filter [force-refresh? #f])
    (map
      (lambda (label)
        `(("title" . ,(substring label (string-length "read-later:")))
          ("action-ui-eval" .  (open-feed '(and (source ,local-source)
                                                (has-label? ,label))))))
      (read-later-labels db))))

(define (read-later-labels db)
  (query-list
    db "SELECT DISTINCT label FROM label_pairs
        WHERE label LIKE 'read-later:%'
        ORDER BY insert_time DESC"))
