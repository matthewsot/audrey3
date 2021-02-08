#lang racket

(require net/url
         xml
         xml/path
         srfi/19
         "web-cache.rkt"
         "../audrey3/utils.rkt")

(provide RSSSource)

(define (RSSSource url)
  (lambda (filter [force-refresh #f])
    (let* ([port (get-cached-port url force-refresh)]
           [xexpr (xml->xexpr (document-element (read-xml port)))]
           [channels (parse-rss xexpr)]
           [items (append-map rss-channel-items channels)])
      (close-input-port port)
      items)))

(struct rss-channel (title description items) #:transparent)

(define (parse-rss xexpr)
  ; Some RSS feeds drop the items directly under the <rdf> (see: arXiv) while
  ; others wrap them in a <channel>. This picks up both.
  (cons (parse-channel xexpr)
        (map parse-channel (find-children 'channel xexpr))))
(define (parse-channel xexpr)
  (rss-channel (se-path* '(channel title) xexpr)
               (se-path* '(channel description) xexpr)
               (filter (curry assoc "title")
                       (map parse-item (find-children 'item xexpr)))))

(define (parse-item xexpr)
  (parse-out-attrs (cddr xexpr)))

(define (parse-out-attrs xexprs [already-seen '()])
  (match xexprs
    ['() '()]
    [`((title ,attrs ,title) ,rest ...)
      #:when (and (string? title) (not (member 'title already-seen)))
      `(("title" . ,title) .
        ,(parse-out-attrs rest `(title . already-seen)))]
    [`((description ,attrs ,descr) ,rest ...)
      #:when (and (string? descr) (not (member 'descr already-seen)))
      `(("description" . ,descr) .
        ,(parse-out-attrs rest `(descr . ,already-seen)))]
    [`((link ,attrs ,url) ,rest ...)
      #:when (and (string? url) (not (member 'url already-seen)))
      `(("url" . ,url) .
        ,(parse-out-attrs rest `(url . ,already-seen)))]
    [`((,(or 'pubDate 'published) ,attrs ,date-str) ,rest ...)
      #:when (and (string? date-str) (not (member 'timestamp already-seen)))
      (let ([format (pick-format date-str)])
        (append
          (with-handlers ([exn:fail? (lambda (e) '())])
            `(("timestamp" .
               ,(time-second
                  (date->time-monotonic
                    (string->date date-str format))))))
          (parse-out-attrs rest `(timestamp . ,already-seen))))]
    [`(,a ,rest ...) (parse-out-attrs rest)]))

(define (pick-format date-str)
  (if (or (string-contains? date-str "+")
          (string-contains? date-str "-"))
      "~a, ~d ~b ~Y ~H:~M:~S ~z"
      "~a, ~d ~b ~Y ~H:~M:~S"))

(define (strings-path path xexpr)
  (string-join (filter string? (se-path*/list path xexpr))))
(define (filter-by-tag tag items)
  (filter (lambda (item) (and (pair? item) (eqv? (car item) tag))) items))
(define (find-children tag xexpr) (filter-by-tag tag (cddr xexpr)))
