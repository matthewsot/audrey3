#lang racket

(require "charterm/main.rkt")
(require "utils.rkt")
(require "lview.rkt")
(require "pager.rkt")
(require "filter.rkt")
(require "feed.rkt")
(require "feed-item.rkt")
(require "feeddef.rkt")
(require "local-db.rkt")
(require "editor.rkt")
(require db)
(require racket/date)
(require racket/system)

(provide ui-main
         register-key-handlers)

(define state-keys '(context feed lview pager checkpoint db))
(define (state-get state key)
  (vector-ref state (index-of state-keys key)))
(define-syntax state-set
  (syntax-rules ()
    [(state-set state) (vector-copy state)]
    [(state-set state [k v] cr ...)
     (let ([state (state-set state cr ...)])
       (vector-set! state (index-of state-keys k) v)
       state)]))
(define (base-state db) (vector 'feed #f #f #f #f db))

(define (ui-main feed-INBOX db)
  (with-charterm
    (write-header "Audrey3")
    (let* ([state (base-state db)]
           [state (ui-eval `(open-feed (feed (quote ,feed-INBOX)) #f) state)])
      (wait-for-key state))
    (charterm-clear-screen)))

(define (feedify obj state)
  (if (list? obj) (build-feed obj (state-get state 'db)) obj))

(define (ui-eval expr state)
  (match expr
    [`,x #:when (not (list? x)) x]
    [`(,rator ,rands ...)
      #:when (and (symbol? rator)
                  (eqv? (string-ref (symbol->string rator) 0) #\*))
      (ui-eval `(,(string->symbol
                    (string-append
                      (symbol->string (state-get state 'context))
                      (substring (symbol->string rator) 1)))
                 . ,rands)
               state)]
    [`(quote ,a) a]
    [`(quasiquote (,u ,a)) #:when (equal? u 'unquote) (ui-eval a state)]
    [`(quasiquote (,a . ,r))
      `(,(ui-eval (list 'quasiquote a) state) .
         ,(ui-eval (list 'quasiquote r) state))]
    [`(quasiquote ,x) #:when (not (pair? x)) x]
    [`(open-feed ,feed ,checkpoint?)
      (set-state-feed
        state
        (read-feed (feedify (ui-eval feed state) state))
        (ui-eval checkpoint? state))]
    [`(reset-history) (state-set state ['checkpoint #f])]
    [`(open-feed ,feed) (ui-eval `(open-feed ,feed #t) state)]
    [`(feed ,feeddef) (feedify (ui-eval feeddef state) state)]
    [`(write-header ,text) (write-header (ui-eval text state)) state]
    [`(current-state) state]
    [`(stateless ,f) (lambda args (apply f args) state)]
    [`(feed-first) (update-state state 'lview lview-first-item)]
    [`(feed-last)  (update-state state 'lview lview-last-item)]
    [`(feed-next)  (update-state state 'lview lview-next-item)]
    [`(feed-prev)  (update-state state 'lview lview-prev-item)]
    [`(pager-first) (update-state state 'pager pager-first-line)]
    [`(pager-last)  (update-state state 'pager pager-last-line)]
    [`(pager-next)  (update-state state 'pager pager-next-line)]
    [`(pager-prev)  (update-state state 'pager pager-prev-line)]
    [`(fetch-current-feed ,force?)
      (set-state-feed state (read-feed (state-get state 'feed) force?) #f #t)]
    [`(refilter-current-feed)
      (set-state-feed
        state
        (refilter-feed (state-get state 'feed) (state-get state 'db))
        #f #t)]
    [`(quit) #f]
    [`(history-back)
      (let ([new-state (state-get state 'checkpoint)])
        (if (eqv? new-state #f)
            #f
            (set-state-feed
              (state-set state ['checkpoint (state-get new-state 'checkpoint)])
              (state-get new-state 'feed)
              #f)))]
    [`(current-item) (get-selected state)]
    [`(current-feeddef) (feed-feeddef (state-get state 'feed))]
    [`(save-item ,item)
      (local-save-item (ui-eval item state) (state-get state 'db))
      state]
    [`(give-label ,item ,label ,id-key)
      (let* ([item (ui-eval item state)]
             [id-key (ui-eval id-key state)]
             [label (ui-eval label state)])
        (give-label item label id-key (state-get state 'db))
        state)]
    [`(begin) state]
    [`(begin ,expr) (ui-eval expr state)]
    [`(begin ,exprs ...)
      ; TODO: This might cause problems if one of the intermediate exprs
      ; doesn't evaluate to a state.
      (ui-eval `(begin . ,(cdr exprs)) (ui-eval (car exprs) state))]
    [`(edit ,template ,sexpr)
      (edit (ui-eval template state) (ui-eval sexpr state))]
    [`(car ,l) (car (ui-eval l state))]
    [`(edit ,template) (ui-eval `(edit ,template #f) state)]
    [`(relayout)
      ; Closing the pager forces the lview to resize (currently, even if it's
      ; not open in the first place).
      (ui-eval `(close-pager) state)]
    [`(passes ,filter ,item)
      (check-filter (ui-eval filter state)
                    (ui-eval item state)
                    (state-get state 'db))]
    [`(get-attr ,attr ,item)
      (feed-item->attr-value (ui-eval item state) (ui-eval attr state))]
    [`(if ,cond ,then ,else)
      (if (ui-eval cond state) (ui-eval then state) (ui-eval else state))]
    [`(view-item ,item)
      (let* ([item (ui-eval item state)]
             [start-line (quotient (charterm-lines) 2)]
             [n-lines (add1 (- (charterm-lines) start-line))]
             [lines (feed-item->pager-lines item (charterm-cols))]
             [item-pager (pager lines start-line n-lines 0)]
             [lview-lines (- (charterm-lines) n-lines 1)]
             [smaller-lview (lview-resize (state-get state 'lview)
                                          lview-lines)])
        (draw-pager item-pager)
        (state-set state
                   ['context 'pager]
                   ['lview smaller-lview]
                   ['pager item-pager]))]
    [`(close-pager)
      ; NOTE: Before editing, make sure it still works with (relayout).
      (let ([lview (lview-resize (state-get state 'lview) (feed-full-size))])
        (state-set state
                   ['context 'feed]
                   ['lview lview]
                   ['pager #f]))]
    [`(ui-eval ,expr) (ui-eval (ui-eval expr state) state)]
    [`(,rator ,rands ...)
      (apply (ui-eval rator state) (map (curryr ui-eval state) rands))]))

(define (set-state-feed state feed checkpoint? [keep-selected? #f])
  (let* ([selected-index (if keep-selected?
                             (lview-selected-index (state-get state 'lview))
                             0)]
         [lview (feed->lview feed 2 (feed-full-size) selected-index)]
         [restore (if checkpoint? state (state-get state 'checkpoint))])
    (draw-lview lview)
    (write-header (format "~a" restore))
    (state-set state ['feed feed]
                     ['lview lview]
                     ['pager #f]
                     ['checkpoint restore])))

(define (update-state state key op)
  (state-set state [key (op (state-get state key))]))

(define (feed-full-size) (sub1 (charterm-lines)))

; feed-interact is the interaction loop that we will use while a feed is being
; displayed to the screen.
(define (wait-for-key state)
  ; We wait for a keyboard input from the user.
  (if (eqv? state #f)
      #f
      (let ([key (charterm-read-key)])
        ; Print some debug information.
        (write-header (string-append "You Pressed: " (format "~S" key)))
        (cond
          [(hash-ref HANDLERS `(,(state-get state 'context) . ,key) #f)
           => (lambda (expr) (wait-for-key (ui-eval expr state)))]
          [(hash-ref HANDLERS `(_ . ,key) #f)
           => (lambda (expr) (wait-for-key (ui-eval expr state)))]
          [(hash-ref HANDLERS `(_ . _) #f)
           => (lambda (expr) (wait-for-key (ui-eval expr state)))]
          [else (wait-for-key state)]))))

(define HANDLERS (make-hash))

(define-syntax register-key-handlers
  (syntax-rules ()
    ; Base: no cases.
    [(register-key-handlers) (void)]
    ; Base: no contexts.
    [(register-key-handlers ['() handlers ...]) (void)]
    ; Base: no handlers
    [(register-key-handlers [context]) (void)]
    ; Recursive: multiple contexts
    [(register-key-handlers [(c1 cr ...) handlers ...])
     (begin
         (register-key-handlers [c1 handlers ...])
         (register-key-handlers [(cr ...) handlers ...]))]
    ; Recursive: one context, one handler, multiple keys
    [(register-key-handlers [c1 ((k1 kr ...) action)])
     (begin
         (register-key-handlers [c1 (k1 action)])
         (register-key-handlers [c1 ((kr ...) action)]))]
    ; Base: one context, one handler
    [(register-key-handlers [c (k a)])
     (hash-set! HANDLERS `(,(quote c) . ,(quote k)) a)]
    ; Recursive: multiple handlers
    [(register-key-handlers [c h1 hr ...])
     (begin
         (register-key-handlers [c h1])
         (register-key-handlers [c hr ...]))]
    ; Recursive: multiple cases.
    [(register-key-handler case1 cases-r ...)
     (begin
         (register-key-handlers case1)
         (register-key-handlers cases-r ...))]))

(define (lview-fullsize lview)
  (lview-resize lview (sub1 (charterm-lines))))

(define (get-selected state)
  (list-ref (feed-items (state-get state 'feed))
            (lview-selected-index (state-get state 'lview))))

; Writes the header line.
(define (write-header header)
  (write-separator header 1))
