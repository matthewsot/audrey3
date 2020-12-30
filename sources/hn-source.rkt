#lang racket

(require net/url)
(require json)
(require "web-cache.rkt")
(require "../audrey3/utils.rkt")
(require "../audrey3/abstract-filter.rkt")

(provide HNSource)

(define HNSource
  (lambda (filter [force-refresh? #f])
    (let* ([abstract (abstract-filter filter)]
           [since (cadr (hash-ref abstract '(attr "timestamp")))]
           [min-comments (cadr (hash-ref abstract
                                         '(attr "num-comments")
                                         '(interval . (0 . +inf.0))))])
      (latest-items since min-comments 0 force-refresh?))))

(define api-base "https://hn.algolia.com/api/v1/search_by_date")

(define (latest-items since-timestamp min-comments page force-refresh?)
  (let* ([url (string-append
                api-base
                "?tags=story"
                "&numericFilters="
                "created_at_i>=" (format "~a" since-timestamp)
                ",num_comments>=" (format "~a" min-comments)
                "&hitsPerPage=100"
                "&page=" (format "~a" page))]
         [port (get-cached-port url force-refresh?)]
         [jsexpr (read-json port)]
         [items (map parse-item (hash-ref jsexpr 'hits))])
    (close-input-port port)
    (if (>= page (hash-ref jsexpr 'nbPages))
        items
        (append
          items
          (latest-items since-timestamp min-comments
                        (add1 page) force-refresh?)))))

(define (parse-item jsexpr)
  `(("title" . ,(hash-ref jsexpr 'title))
    ("timestamp" . ,(hash-ref jsexpr 'created_at_i))
    ("url" . ,(url-from-item jsexpr))
    ("num-comments" . ,(hash-ref jsexpr 'num_comments))
    ("hn-id" . ,(hash-ref jsexpr 'objectID))
    ("author" . ,(hash-ref jsexpr 'author))))

(define (url-from-item jsexpr)
  (if (eqv? (hash-ref jsexpr 'url) (json-null))
      (string-append "https://news.ycombinator.com/item?id="
                     (hash-ref jsexpr 'objectID))
      (hash-ref jsexpr 'url)))
