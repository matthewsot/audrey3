#lang racket

(require net/url)
(require xml)
(require xml/path)
(require "web-cache.rkt")
(require "../audrey3/utils.rkt")

(provide RSSSource)

(struct rss-channel (title description items) #:transparent)

(define (parse-rss xexpr) (map parse-channel (find-children 'channel xexpr)))
(define (parse-channel xexpr)
  (rss-channel (se-path* '(channel title) xexpr)
               (se-path* '(channel description) xexpr)
               (map parse-item (find-children 'item xexpr))))
(define (parse-item xexpr)
  (let ([title (strings-path '(item title) xexpr)]
        [url (strings-path '(item link) xexpr)]
        [description (strings-path '(item description) xexpr)])
    `(("title" . ,title)
      ("url" . ,url)
      ("description" . ,description))))
(define (strings-path path xexpr)
  (string-join (filter string? (se-path*/list path xexpr))))
(define (filter-by-tag tag items)
  (filter (lambda (item) (and (pair? item) (eqv? (car item) tag))) items))
(define (find-children tag xexpr) (filter-by-tag tag (cddr xexpr)))

(define (RSSSource url)
  (lambda (filter [force-refresh #f])
    (let* ([port (get-cached-port url force-refresh)]
           [xexpr (xml->xexpr (document-element (read-xml port)))]
           [channels (parse-rss xexpr)]
           [items (rss-channel-items (car channels))])
      (close-input-port port)
      items)))
