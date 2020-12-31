#lang racket

(require "../audrey3/utils.rkt")

(provide ActionListSource)

; Each named-action should be a pair ("name" . feeddef).
(define ActionListSource
  (lambda named-actions
    (lambda (filter [force-refresh? #f])
      (map named-action->item named-actions))))

(define (named-action->item named-action)
  (let ([name (car named-action)]
        [action (cdr named-action)])
    ; TODO: Format the action as a string to use as an ID.
    `(("title" . ,name) ("action-ui-eval" . ,action))))
