#lang racket

(require "charterm/main.rkt")
(require "utils.rkt")

(provide lview
         lview-start-line
         draw-lview
         lview-set-selected
         lview-first-item
         lview-last-item
         lview-next-item
         lview-prev-item
         lview-resize
         lview-selected-index)

; The items are just strings, start-line and n-lines tell where to draw the
; lview, and selected-index is the index of the currently selected item.
(struct lview (items start-line n-lines selected-index))

(define (draw-lview lview)
  (clear-lines (lview-start-line lview) (lview-n-lines lview))
  (charterm-cursor 1 (lview-start-line lview))
  (draw-page (list-tail (lview-items lview)
                        (current-page-start lview))
             (lview-n-lines lview)
             (current-line-on-page lview)))

; Draws a list of items, always starting at item 0 and always at the current
; cursor index.
(define (draw-page items remaining-lines selected-index)
  (if (or (null? items) (zero? remaining-lines))
      ; Either out of lines or out of items!
      (clear-lines-here remaining-lines)
      ; Draw the next item and recurse.
      (begin
        (draw-item (car items) (zero? selected-index))
        (draw-page (cdr items)
                   (sub1 remaining-lines)
                   (sub1 selected-index)))))

; Draws a single item.
(define (draw-item item is-selected)
  (if is-selected (charterm-inverse) (charterm-normal))
  (charterm-display (ljust-force (strip-to-ascii item) (charterm-cols)))
  (charterm-normal))

; Method that changes which item is selected.
(define (lview-set-selected old-lview new-selected)
  (let ([new-lview (struct-copy
                    lview
                    old-lview
                    [selected-index
                      (clip-to-valid-index new-selected old-lview)])])
    (if (eq? (current-page-start old-lview) (current-page-start new-lview))
        (swap-selected old-lview new-lview)
        (draw-lview new-lview))
    new-lview))
; When they're on the same page, we just write the old one unselected and the
; new one selected.
(define (swap-selected lview new-lview)
  (charterm-cursor 1 (screen-line lview))
  (draw-item (list-ref (lview-items lview) (lview-selected-index lview)) #f)
  (charterm-cursor 1 (screen-line new-lview))
  (draw-item (list-ref (lview-items lview) (lview-selected-index new-lview)) #t))

; Returns the index of the @index element on its page.
(define (lview-line-on-page index lview) (remainder index (lview-n-lines lview)))
(define (current-line-on-page lview) (lview-line-on-page (lview-selected-index lview) lview))
(define (screen-line lview)
  (+ (lview-start-line lview) (current-line-on-page lview)))
; Returns the index of the first element on the same page as @index.
(define (lview-page-start index lview) (- index (lview-line-on-page index lview)))
(define (current-page-start lview) (lview-page-start (lview-selected-index lview) lview))
(define (clip-to-valid-index index lview)
  (clip index 0 (sub1 (length (lview-items lview)))))

; Helpers for changing which item is selected.
(define (lview-next-item lview)
  (lview-set-selected lview (add1 (lview-selected-index lview))))
(define (lview-prev-item lview)
  (lview-set-selected lview (sub1 (lview-selected-index lview))))
(define (lview-first-item lview) (lview-set-selected lview 0))
(define (lview-last-item lview)
  (lview-set-selected lview (sub1 (length (lview-items lview)))))

(define (lview-resize old-lview new-n-lines)
  (let* ([new-lview (struct-copy lview old-lview [n-lines new-n-lines])])
    (draw-lview new-lview)
    new-lview))
