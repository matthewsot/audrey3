#lang racket

(require "audrey3/main.rkt"
         "sources/rss-source.rkt"
         "sources/local-source.rkt"
         "sources/hn-source.rkt"
         "sources/hn-discussions.rkt"
         "sources/hn-comments.rkt"
         "sources/action-list.rkt"
         "sources/read-later-list.rkt"
         "printers/print.rkt"
         "printers/webpage.rkt"
         db
         racket/date
         racket/system)

; This is where we will save our labels and metadata for any items that we want
; to save to read later.
(define LocalDB (open-or-create-db "private/database-local.db"))

; Registering a source makes its name available for use in the (source ...)
; feeddef command.
(register-source 'ReutersEcon
  (RSSSource
    "https://www.reutersagency.com/feed/?best-sectors=economy&post_type=best"))
(register-source 'Local (LocalDBSource LocalDB))
(register-source 'HN HNSource)
(register-source 'HNDiscussions HNDiscussionSource)
(register-source 'HNComments HNCommentSource)

; This generates a label to mark things we want to read today. Note that it's
; important this is a method, so it will update even if we leave Audrey3
; running for multiple days.
(define (read-today-label)
  (string-append "read-later:" (date->string (current-date))))

(define (read-today-feeddef)
  `(and (source Local)
        (has-label? ,(read-today-label))
        (not (has-label? "ignore"))))

; This creates a source that reads all of the read-later:(date) labels and
; allows us to select from them.
(register-source 'ReadLaterDays (ReadLaterListSource 'Local LocalDB))

; An ActionListSource lets you present a pre-set list of UI actions as items.
(register-source
  'Main
  (ActionListSource
    '("Reuters Econ Feed" .
      (open-feed '(and (source ReutersEcon)
                       (not (has-label? "triaged")))))
    '("HN Popular Today" .
      (open-feed '(and (source HN)
                       (> (attr "timestamp") (- (now) (days 1)))
                       (> (attr "num-comments") 5)
                       (not (has-label? "triaged")))))
    `("Read Today" . (open-feed ',(read-today-feeddef)))
    `("All Read-Later-Days" . (open-feed '(source ReadLaterDays)))))

; This method takes an item and attempts to print it using the listed printers.
; The default print-webpage printer calls wkhtmltopdf.
(define print-item (curryr try-print-item `(,print-webpage)))

; Now we register actions to be performed on certain context-keypress
; combinations.
(register-key-handlers
  (_
   [ctrl-c '(quit)]
   [#\M '(begin (open-feed '(source Main))
                (reset-history))]
   [_ `(write-header "Key not found.")])
  ([feed pager]
   [#\g '(*-first)]
   [#\G '(*-last)]
   [(#\h down) '(*-next)]
   [(#\t up) '(*-prev)]
   [#\p `(begin (write-header "Printing...")
                ((stateless ,print-item) (current-item))
                (write-header "Printing complete!"))]
   [#\c '(open-feed `(and (sources HNDiscussions)
                          (= (attr "about-url")
                             ,(get-attr "url" (current-item)))))])
  (feed
   [#\q '(history-back)]
   [#\f `(fetch-current-feed #t)]
   [#\I `(begin (give-label (current-item) "triaged" "url")
                (fetch-current-feed #f))]
   [#\R `(begin (save-item (current-item))
                (give-label (current-item) "read-later" "url")
                (give-label (current-item) "triaged" "url")
                (give-label (current-item) (,read-today-label) "url")
                (fetch-current-feed #f))]
   [#\* `(open-feed (,read-today-feeddef))]
   [#\e `(open-feed
           (car (edit "templates/edit-feeddef.rkt" (current-feeddef))))]
   [return `(if (passes '(has-attr "action-ui-eval") (current-item))
                (ui-eval (get-attr "action-ui-eval" (current-item)))
                (view-item (current-item)))])
  (pager
   [#\H '(begin (feed-next) (view-item (current-item)))]
   [#\T '(begin (feed-prev) (view-item (current-item)))]
   [(#\q escape) '(close-pager)]))

; Finally, we start the default Audrey3 UI.
(ui-main '(source Main) LocalDB)
