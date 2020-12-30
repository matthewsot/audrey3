#lang racket

(provide edit)

(define (edit [template-file #f] [append-to-template #f])
  (let ([temp-path (make-temporary-file "rkttemp~a.rkt" template-file)])
    (cond
      [append-to-template (append-to-file append-to-template temp-path)])
    (system (format "vim ~a" temp-path))
    (void (system "tput civis"))
    (let ([script (read-file-as-expr temp-path)])
      (delete-file temp-path)
      script)))

(define (append-to-file sexpr path)
  (let ([out-file (open-output-file path #:exists 'append)])
    (write sexpr out-file)
    (close-output-port out-file)))

(define (read-file-as-expr path)
  (let* ([in-file (open-input-file path)]
         [expr (file->exprs in-file)])
    (close-input-port in-file)
    expr))

(define (file->exprs file)
  (let ([datum (read file)])
    (if (eof-object? datum)
        '()
        (cons datum (file->exprs file)))))
