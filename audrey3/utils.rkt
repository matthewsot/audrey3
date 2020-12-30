#lang racket

(require "charterm/main.rkt")
(require racket/serialize)
(require file/md5)

; Returns @str padded to length @desired-length.
; If @str is longer than @desired-length, cuts off with [...]
(define (ljust-force str desired-length [pad-str " "])
  (~a str #:width desired-length #:limit-marker "[...]" #:pad-string pad-str))

; Helper to clip a numerical value.
(define (clip val low high) (max low (min val high)))

; Helpers for getting the number of cols/lines from charterm.
(define (charterm-cols)
  (let-values ([(cols lines) (charterm-screen-size)]) cols))
(define (charterm-lines)
  (let-values ([(cols lines) (charterm-screen-size)]) lines))

; Helpers to clear blocks of the terminal at once.
(define (clear-lines-here n-lines)
  (charterm-normal)
  (charterm-display (make-string (* (charterm-cols) n-lines) #\ )))
(define (clear-lines first-line n-lines)
  (charterm-cursor 1 first-line) (clear-lines-here n-lines))

(define (strip-to-ascii str)
  (string-replace
    (string-replace (string-replace str "’" "'") "‘" "'")
    "\n" " "))

(define (string->hashed str)
  (bytes->string/locale (md5 str)))

(define (strify obj)
  (let* ([serialized (open-output-string)])
    (write (serialize obj) serialized)
    (get-output-string serialized)))

(define (destrify str)
  (deserialize (read (open-input-string str))))

(define (write-separator text line)
  (charterm-cursor 1 line)
  (charterm-normal)
  (charterm-bold)
  (charterm-display (format-header text)))

; Formats the header line.
(define (format-header header)
  (ljust-force (string-append "~" header) (charterm-cols) "~"))

(provide ljust-force
         clip
         charterm-cols
         charterm-lines
         clear-lines
         clear-lines-here
         strip-to-ascii
         string->hashed
         strify
         destrify
         write-separator)
