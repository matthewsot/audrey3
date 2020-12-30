#lang racket

(require net/url)
(require "../audrey3/utils.rkt")

(provide get-cached-port)

(define cache-dir "private/cache-dir")

; Drop-in replacement to get-pure-port, except it takes a string URL.
(define (get-cached-port url force-refresh)
  (let* ([hash (string->hashed url)]
         [cache-file (string-append cache-dir "/" hash)])
    (if (or force-refresh (not (file-exists? cache-file)))
        (begin
          (download-to-file url cache-file)
          (get-cached-port url #f))
        (open-input-file cache-file))))

(define (download-to-file url cache-file)
  ; I guess there's officially a race condition here...
  (if (directory-exists? cache-dir) (void) (make-directory cache-dir))
  (let ([in-port (get-pure-port (string->url url))]
        [out-file (open-output-file cache-file #:exists 'truncate/replace)])
    (write-bytes (port->bytes in-port) out-file)
    (close-input-port in-port)
    (close-output-port out-file)))
