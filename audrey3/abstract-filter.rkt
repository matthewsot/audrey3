#lang racket

(require racket/set
         racket/date)
(provide abstract-filter)

; Returns an over-approximation of filter. This is pretty coarse, but it's fine
; because we don't really have state or anything.
(define (abstract-filter filter [already-flipped #f])
  (match filter
         [`(or) #f]
         [`(or ,clause ,others ...)
           (join (abstract-filter clause)
                 (abstract-filter (cons 'or others)))]
         [`(and) #t]
         [`(and ,clause ,others ...)
           (meet (abstract-filter clause)
                 (abstract-filter (cons 'and others)))]
         [`(not ,filter)
           (negate (abstract-filter filter))]
         [`(,op ,k ,v)
           (let ([key (abstract-key k)]
                 [value (abstract-value v)])
             (cond
               [(or (eqv? key #t) (eqv? value #t))
                (if already-flipped
                    #t
                    (abstract-filter `(,(reverse-op op) ,v ,k) #t))]
               [(or (eqv? op '<) (eqv? op '<=))
                (make-hash `([,key . (interval . (-inf.0 . ,value))]))]
               [(or (eqv? op '>) (eqv? op '>=))
                (make-hash `([,key . (interval . (,value . +inf.0))]))]
               [(and (eqv? op '=) (number? value))
                (make-hash `([,key . (interval . (,value . ,value))]))]
               [(and (eqv? op '=) (string? value))
                (make-hash `([,key . (val-in . (,value))]))]
               [else #t]))]
         [`(has-label? ,label)
           (make-hash `([any-label . (val-in . (,label))]))]
         ['#t #t]
         ['#f #f]
         [_ #t]))

(define (reverse-op op)
  (match op
         ['> '<=]
         ['>= '<]
         ['< '>=]
         ['<= '>]
         [_ #t]))

(define (abstract-key expr)
  (match expr
         [`title 'title]
         [`(attr ,name)
           #:when (or (symbol? name) (string? name))
           expr]
         [_ #t]))

; TODO merge with eval-filter
(define (abstract-value expr)
  (match expr
         [`,n #:when (number? n) n]
         [`,s #:when (string? s) s]
         [`(now) (current-seconds)]
         [`(today) (date->seconds
                     (struct-copy date (current-date)
                                  [second 0] [hour 0] [minute 0]))]
         [`(- ,a ,b) (- (abstract-value a) (abstract-value b))]
         [`(days ,n) (* (* 60 60 24) (abstract-value n))]
         [_ #t]))

(define (meet A B)
  (match `(,A ,B)
    [`((interval . (,lowA . ,highA)) (interval . (,lowB . ,highB)))
      `(interval . (,(max lowA lowB) . ,(min highA highB)))]
    [`((val-in . ,inA) (val-in . ,inB))
      `(val-in . ,(set-intersect inA inB))]
    [`((val-out . ,outA) (val-out . ,outB))
      `(val-in . ,(set-union outA outB))]
    [`(#f ,_) #f] [`(,_ #f) #f]
    [`(#t ,other) other] [`(,other #t) other]
    [`(,(hash-table (keysA valsA) ...) ,(hash-table (keysB valsB) ...))
      (for ([key keysA])
        (if (hash-has-key? B key)
            (hash-set! B key (meet (hash-ref A key) (hash-ref B key)))
            (hash-set! B key (hash-ref A key))))
      B]))

(define (join A B)
  (match `(,A ,B)
    [`((interval . (,lowA . ,highA)) (interval . (,lowB . ,highB)))
      `(interval . (,(min lowA lowB) . ,(max highA highB)))]
    [`((val-in . ,inA) (val-in . ,inB))
      `(val-in . ,(set-union inA inB))]
    [`((val-out . ,outA) (val-out . ,outB))
      `(val-in . ,(set-intersect outA outB))]
    [`(#t ,_) #t] [`(,_ #t) #t]
    [`(#f ,other) other] [`(,other #f) other]
    [`(,(hash-table (keysA valsA) ...) ,(hash-table (keysB valsB) ...))
      (for ([key keysA])
        (if (hash-has-key? B key)
            (hash-set! A key (join (hash-ref A key) (hash-ref B key)))
            (hash-remove! A key)))
      A]))

(define (negate A)
  (match A 
    ['#t #f]
    ['#f #t]
    [(hash-table (key `(val-in . ,in)))
     (make-hash `((,key . (val-out . ,in))))]
    [(hash-table (key `(val-out . ,out)))
     (make-hash `((,key . (val-in . ,out))))]
    [_ #t]))
