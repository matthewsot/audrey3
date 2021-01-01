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
         feed-feeddef)

; Each 'source' here is actually a (source . filter) pair.
(struct feed (feeddef sources items db))

; Builds a new feed, but does not yet get any of the items
(define (build-feed feeddef db)
  (feed feeddef (feeddef->sources feeddef db) '() db))

; Returns a copy of current-feed with @items populated.
(define (read-source source [force? #f])
  (source force?))

(define (read-feed current-feed [force? #f])
  (let* ([items (append-map (curryr read-source force?)
                            (feed-sources current-feed))])
    (struct-copy feed current-feed [items items])))

(define (feed->lview feed start-line n-lines selected-index)
  (let* ([items (map feed-item-title (feed-items feed))]
         [selected-index (clip selected-index 0 (sub1 (length items)))])
    (lview items start-line n-lines selected-index)))
