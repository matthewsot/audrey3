# Configuring the UI
Currently, the UI is always in one of two different "contexts:"
1. The `feed` context, which only shows the titles of the different items in
   the current feed.
2. The `pager` context, which shows the titles of the different items in the
   background with the foreground being occupied by a window showing details
   about the currently-selected item.
More contexts may be added in the future.

The UI is driven by keypresses.

At each keypress, the UI checks for a corresponding _handler_ for that keypress
in that specific context, written in a particular domain-specific language. You
can find examples of how to register these handlers, and what the DSL looks
like, near the bottom of [example.rkt](example.rkt).

The language should hopefully be relatively self-explanatory. Some things to
watch out for:
1. When an operator starts with `*`, the `*` is replaced by the name of the
   current context. So `*-first` in the `feed` context will select the first
   item in the feed, while `*-first` in the `pager` context will scroll to the
   first line in the pager.
2. The DSL itself has some support for quoting, backquoting, and unquoting. But
   we also write the scripts in Racket using such features. So it can sometimes
   be important to differentiate carefully between defining a script like
```
`(open-feed '(and (source xyz) (> timestamp (- ,(now) (days 1)))))
```
versus
```
'(open-feed `(and (source xyz) (> timestamp (- ,(now) (days 1)))))
```
   The big difference is that the former will filter for items posted at
   earliest one day _before Audrey3 was last started_ while the second will
   filter for items posted at earliest one day _before that specific key
   was pressed_.
3. Every action in the DSL should return a new UI `state`. As long as you stick
   to the methods built-in to the UI DSL and don't do anything to crazy, this
   shouldn't be a problem. But, it is possible to call your own arbitrary
   Racket functions. This should be done with care to be sure that your
   functions always correctly return a new state. If your function does not
   need to modify the state of the UI at all, you can wrap it like so:
   `(stateless ,yourfn)` to get a variant of the function that returns the
   current state unchanged.
