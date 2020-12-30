#lang racket

(require "feed-item.rkt")
(require "utils.rkt")
(require db)
(provide get-labels
         has-label?
         give-label
         open-or-create-db
         local-save-item)

(define (open-or-create-db file)
  (let ([db (sqlite3-connect #:database file
                             #:mode 'create)])
    (query-exec db "CREATE TABLE IF NOT EXISTS
                    label_pairs(attribute TEXT, value TEXT, label TEXT,
                                UNIQUE(attribute, value, label))")
    (query-exec db "CREATE TABLE IF NOT EXISTS
                    local_items(meta_id BLOB,
                                racket_code BLOB,
                                UNIQUE(meta_id))")
    (query-exec db "CREATE TABLE IF NOT EXISTS
                    local_item_attributes(
                      local_item,
                      attribute TEXT,
                      value BLOB,
                      str_value TEXT,
                      num_value NUMERIC,
                      FOREIGN KEY(local_item) REFERENCES local_items(rowid)
                      )")
    db))

(define (get-labels item db)
  (let*-values ([(start-query) "SELECT label FROM label_pairs WHERE "]
                [(sql params) (to-sql-dnf item)]
                [(query) (string-append start-query sql)])
    (apply (curry query-list db query) params)))

(define (to-sql-dnf attrs)
  (cond
    [(null? attrs) (values "" '())]
    [else
      (let-values ([(sub-sql sub-params) (to-sql-dnf (cdr attrs))])
        (if (equal? sub-sql "")
            (values "((attribute = ?) AND (value = ?))"
                    `(,(caar attrs) ,(cdar attrs)))
            (values (string-append "((attribute = ?) AND (value = ?))"
                                   " OR " sub-sql)
                    `(,(caar attrs) ,(cdar attrs) . ,sub-params))))]))

(define (has-label? item label db)
  (member label (get-labels item db)))

(define (give-label item label id-key db)
  (let ([id (feed-item->id item id-key)])
    (if (id-has-label? id-key id label db)
        (void)
        (query-exec
          db
          "INSERT INTO label_pairs(attribute, value, label)
          VALUES ($1, $2, $3)"
          id-key id label))))

(define (id-has-label? key id label db)
  ; TODO this can probably be a COUNT or something.
  (> (length
       (query-rows
         db
         "SELECT * FROM label_pairs
         WHERE attribute = ? AND value = ? AND label = ?"
         key id label))
     0))

; Returns all local_items that have the same primary_id. We assume the
; primary_id is the first one.
(define (get-local item db)
  (query-rows
    db "SELECT racket_code FROM local_items WHERE meta_id = ?"
    (feed-item->meta-id item)))

(define (has-local? item db)
  (not (null? (get-local item db))))

(define (local-save-item item db)
  (let* ([result
           (query db "INSERT OR IGNORE INTO local_items (meta_id, racket_code)
                      VALUES ($1, $2)"
                  (feed-item->primary-id item) (strify item))]
         [info (simple-result-info result)]
         [rowid (cdr (or (assoc 'insert-id info) '(_ . -1)))]
         [n-affected (cdr (or (assoc 'affected-rows info) '(_ . 0)))])
    (cond
      [(> n-affected 0)
       (for ([keyval item])
         (query-exec
           db
           "INSERT INTO local_item_attributes
            (local_item, attribute, value, str_value, num_value)
            VALUES (?, ?, ?, ?, ?)"
           rowid
           (car keyval)
           (strify (cdr keyval))
           (maybe-string (cdr keyval))
           (maybe-number (cdr keyval))))])))

(define (maybe-string v) (if (string? v) v sql-null))

(define (maybe-number v) (if (number? v) v sql-null))
