#lang racket

(require "../audrey3/feed-item.rkt"
         net/url)
(provide download-arxiv-pdf)

(define (download-arxiv-pdf item)
  (cond
    [(is-arxiv? item)
     (let* ([url (abs->pdf (feed-item->attr-value item "url"))]
            [out-name "private/printed.pdf"]
            [in-port (get-pure-port (string->url url))]
            [out-file (open-output-file out-name #:exists 'truncate/replace)])
       (write-bytes (port->bytes in-port) out-file)
       (close-input-port in-port)
       (close-output-port out-file)
       #t)]
    [else #f]))

(define (is-arxiv? item)
  (and (feed-item->has-attr? item "url")
       (string-prefix? (feed-item->attr-value item "url")
                       "http://arxiv.org/abs/")))

(define (abs->pdf url)
  (string-append
    (string-replace url "http://arxiv.org/abs/" "https://arxiv.org/pdf/")
    ".pdf"))
