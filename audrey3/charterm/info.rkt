#lang setup/infotab

(define mcfly-planet       'neil/charterm:4:5)
(define name               "charterm")
(define mcfly-subtitle     "Character-cell Terminal Interface")
(define blurb              (list mcfly-subtitle))
(define homepage           "http://www.neilvandyke.org/racket/charterm/")
(define mcfly-author       "Neil Van Dyke")
(define repositories       '("4.x"))
(define categories         '(misc))
(define can-be-loaded-with 'all)
(define scribblings        '(("charterm.scrbl" () (gui-library))))
(define primary-file       "main.rkt")
(define mcfly-start        "main.rkt")
(define mcfly-files        '(defaults "demo.rkt"))
(define mcfly-license      "LGPLv3")
(define deps               '("base"
                             "mcfly"))
(define build-deps         '("racket-doc"
                             "scribble-lib"))

(define mcfly-legal
    "Copyright 2012, 2013, 2016, 2017 Neil Van Dyke.  This program is Free
Software; you can redistribute it and/or modify it under the terms of the GNU
Lesser General Public License as published by the Free Software Foundation;
either version 3 of the License, or (at your option) any later version.  This
program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for a
particular purpose.  See http://www.gnu.org/licenses/ for details.  For other
licenses and consulting, please contact the author.")
