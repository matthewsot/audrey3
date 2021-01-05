#lang racket

(require "lview.rkt"
         "utils.rkt"
         "filter.rkt"
         "feed-item.rkt"
         "feeddef.rkt"
         racket/serialize)

(provide build-feed
         read-feed
         feed->lview
         feed-items
         feed-feeddef
         refilter-feed)

; Each 'source' here is actually a (source . filter) pair.
; Each item-with-filter is an (item . filter) pair.
(struct feed (feeddef sources items-with-filters db))

; Builds a new feed, but does not yet get any of the items
(define (build-feed feeddef db)
  (feed feeddef (feeddef->sources feeddef db) '() db))

(define (read-source source [force? #f])
  (source force?))

; Returns a copy of current-feed with @items populated.
(define (read-feed current-feed [force? #f])
  (let* ([items-with-filters (append-map (curryr read-source force?)
                                         (feed-sources current-feed))])
    (struct-copy feed current-feed [items-with-filters items-with-filters])))

(define (refilter-feed current-feed db)
  (struct-copy
    feed
    current-feed
    [items-with-filters
      (filter (lambda (item-filter)
                (check-filter (cdr item-filter) (car item-filter) db))
              (feed-items-with-filters current-feed))]))

(define (feed-items feed)
  (map car (feed-items-with-filters feed)))

(define (feed->lview feed start-line n-lines selected-index)
  (let* ([items (map feed-item-title (feed-items feed))]
         [selected-index (clip selected-index 0 (sub1 (length items)))])
    (lview items start-line n-lines selected-index)))
