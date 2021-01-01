#lang racket

(require "../audrey3/feed-item.rkt"
         net/url)
(provide download-url)

(define (download-url item)
  (cond
    [(feed-item->has-attr? item "url")
     (let* ([url (feed-item->attr-value item "url")]
            [extension (get-extension url)]
            [out-name (string-append "private/printed" extension)]
            [in-port (get-pure-port (string->url url))]
            [out-file (open-output-file out-name #:exists 'truncate/replace)])
       (write-bytes (port->bytes in-port) out-file)
       (close-input-port in-port)
       (close-output-port out-file)
       #t)]
    [else #f]))

(define (get-extension url)
  (match (regexp-match #px"\\.\\w{1,4}$" url)
         [#f ""]
         [`(,ext) ext]))
