#lang racket

(require net/url)
(require json)
(require "web-cache.rkt")
(require "../audrey3/utils.rkt")
(require "../audrey3/abstract-filter.rkt")

(provide HNDiscussionSource)

(define HNDiscussionSource
  (lambda (filter [force-refresh? #f])
    (let* ([abstract (abstract-filter filter)]
           [about-urls (hash-ref abstract '(attr "about-url"))])
      (match about-urls
             [`(val-in . (,urls ...))
               (items-about-urls urls force-refresh?)]))))

(define api-base "https://hn.algolia.com/api/v1/search")

(define (items-about-urls urls force-refresh?)
  (cond
    [(null? urls) '()]
    [else (append (items-about-url (car urls) 0 force-refresh?)
                  (items-about-urls (cdr urls) force-refresh?))]))

(define (items-about-url url page force-refresh?)
  ; TODO: actually escape the URL. Also, maybe merge with the standard HN one.
  (let* ([url (car (string-split url "?"))]
         [api-url (string-append
                    api-base
                    "?tags=(story,ask_hn,show_hn)"
                    "&restrictSearchableAttributes=url"
                    "&query=" url
                    "&hitsPerPage=100"
                    "&page=" (format "~a" page))]
         [port (get-cached-port api-url force-refresh?)]
         [jsexpr (read-json port)]
         [items (map parse-item (hash-ref jsexpr 'hits))])
    (close-input-port port)
    (if (>= page (hash-ref jsexpr 'nbPages))
        items
        (append
          items
          (items-about-url url (add1 page) force-refresh?)))))

; TODO: Merge with the standard HN one.
(define (parse-item jsexpr)
  `(("title" . ,(hash-ref jsexpr 'title))
    ("timestamp" . ,(hash-ref jsexpr 'created_at_i))
    ("url" . ,(string-append "https://news.ycombinator.com/item?id="
                             (hash-ref jsexpr 'objectID)))
    ("about-url" . ,(url-from-item jsexpr))
    ("num-comments" . ,(hash-ref jsexpr 'num_comments))
    ("hn-id" . ,(hash-ref jsexpr 'objectID))
    ("author" . ,(hash-ref jsexpr 'author))
    ("action-ui-eval" .
     (open-feed '(and (source HNComments)
                      (= (attr "about-hn-id")
                         ,(hash-ref jsexpr 'objectID)))))))

; TODO: Merge with the standard HN one.
(define (url-from-item jsexpr)
  (if (eqv? (hash-ref jsexpr 'url) (json-null))
      (string-append "https://news.ycombinator.com/item?id="
                     (hash-ref jsexpr 'objectID))
      (hash-ref jsexpr 'url)))
