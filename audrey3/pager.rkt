#lang racket

(require "charterm/main.rkt")
(require "utils.rkt")

(provide pager
         draw-pager
         pager-next-line
         pager-prev-line
         pager-first-line
         pager-last-line)

; The items are just strings, start-line and n-lines tell where to draw the
; pager, and selected-index is the index of the currently selected item.
(struct pager (lines start-line n-lines scroll))

(define (draw-pager pager)
  (clear-lines (pager-start-line pager) (pager-n-lines pager))
  (write-separator "" (pager-start-line pager))
  (charterm-cursor 1 (add1 (pager-start-line pager)))
  (draw-page (list-tail (pager-lines pager) (pager-scroll pager))
             (sub1 (pager-n-lines pager))))

(define (draw-page lines remaining-lines)
  (if (or (null? lines) (zero? remaining-lines))
      ; Either out of lines to write or lines on screen!
      (clear-lines-here remaining-lines)
      ; Draw the next line and recurse.
      (begin
        (draw-line (car lines))
        (draw-page (cdr lines) (sub1 remaining-lines)))))

; Draws a single line
(define (draw-line line)
  (charterm-normal)
  (charterm-display (ljust-force (strip-to-ascii line) (charterm-cols))))

; Method that changes the scroll.
(define (pager-set-scroll old-pager new-scroll)
  (let ([new-pager (struct-copy
                     pager
                     old-pager
                     [scroll (clip-to-valid-index new-scroll old-pager)])])
    (if (eq? (pager-scroll old-pager) (pager-scroll new-pager))
        (void)
        (draw-pager new-pager))
    new-pager))

(define (clip-to-valid-index index pager)
  (clip index 0 (sub1 (length (pager-lines pager)))))

; Helpers for changing which item is selected.
(define (pager-next-line pager)
  (pager-set-scroll pager (add1 (pager-scroll pager))))
(define (pager-prev-line pager)
  (pager-set-scroll pager (sub1 (pager-scroll pager))))
(define (pager-first-line pager) (pager-set-scroll pager 0))
(define (pager-last-line pager)
  (pager-set-scroll pager (sub1 (length (pager-lines pager)))))
