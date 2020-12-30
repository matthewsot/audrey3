#lang racket

(provide try-print-item)

(define (try-print-item item printers)
  (cond
    [(null? printers) #f]
    [(eqv? #f ((car printers) item))
     (try-print-item item (cdr printers))]
    [else #t]))
