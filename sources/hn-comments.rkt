#lang racket

(require net/url)
(require json)
(require "web-cache.rkt")
(require "../audrey3/utils.rkt")
(require "../audrey3/abstract-filter.rkt")

(provide HNCommentSource)

(define HNCommentSource
  (lambda (filter [force-refresh? #f])
    (let* ([abstract (abstract-filter filter)]
           [story-ids (cdr (hash-ref abstract '(attr "about-hn-id")))])
      (append-map (curryr comments-about force-refresh?) story-ids))))

(define api-base "https://hn.algolia.com/api/v1/items")

(define (comments-about story-id force-refresh?)
  (let* ([url (string-append api-base "/" (format "~a" story-id))]
         [port (get-cached-port url force-refresh?)]
         [jsexpr (read-json port)])
    (append-map parse*-recursive (hash-ref jsexpr 'children))))

(define (parse*-recursive jsexpr [depth 0])
  (cons (parse-item jsexpr depth)
        (append-map (curryr parse*-recursive (add1 depth))
                    (hash-ref jsexpr 'children))))

(define (parse-item jsexpr depth)
  `(("title" . ,(depthify-title (or-deleted (hash-ref jsexpr 'text)) depth))
    ("timestamp" . ,(hash-ref jsexpr 'created_at_i))
    ("url" . ,(string->hashed (url-from-item jsexpr)))
    ("num-children" . ,(length (hash-ref jsexpr 'children)))
    ("hn-text" . ,(or-deleted (hash-ref jsexpr 'text)))
    ("hn-id" . ,(number->string (hash-ref jsexpr 'id)))
    ("about-hn-id" . ,(number->string (hash-ref jsexpr 'story_id)))
    ("author" . ,(hash-ref jsexpr 'author))))

(define (depthify-title title depth)
  (string-append (make-string depth #\.) title))

(define (or-deleted text)
  (if (equal? (json-null) text) "[deleted]" text))

(define (url-from-item jsexpr)
  (if (eqv? (hash-ref jsexpr 'url) (json-null))
      (format
        "https://news.ycombinator.com/item?id=~a" (hash-ref jsexpr 'id))
      (hash-ref jsexpr 'url)))
