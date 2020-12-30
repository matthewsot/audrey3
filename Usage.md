# Usage of the Example Configuration
First, use `raco` to install the packages `db` and `mcfly`.

Then, run
```bash
racket example.rkt
```
The example has been configured to start off by displaying a pre-defined list
of feeds. In fact, this list is also a feed; a feed-of-feeds! You can move up
or down the list with the arrow keys, or `h` and `t` keys (if you are using
QWERTY, you will probably want to remap those to `j` and `k` in `example.rkt`
before continuing).

To open a feed, press `return`.

If you open the Reuter's feed, for example, you should see a list of recent
news articles. You can press `return` to see more details about any article. You
can press `p` to download the article as a PDF file to `private/printed.pdf`
(note: this requires `wkhtmltopdf`, you should download it first if you have
not already).

If you press `I`, you should see that the selected item disappears from the
list. Pressing `I` gives that item the `triaged` label, which indicates you
have already considered that item and no longer wish it to show up in your
default feeds.

If you press `R`, you should see that the item _also_ disappears. However, this
time, in addition to giving it the `triaged` label, it has also been given two
other labels: `read-later` and `read-later-[today's date]`. It has also been
saved to your local database in `private/database-local.db` so you will retain
a copy of the item's metadata even if it disappears from the underlying source.

To see all of the items you have marked `read-later-[today's date]`, press `*`
to open the feed of such items.

You can navigate backwards in your history of visited feeds using `q`.

You can reset your history and navigate back to the original feed-of-feeds by
pressing `M`.

Now, navigate to the `HN Popular Today` feed. You will see a list of popular
posts on the front page of Hacker News.

What exactly defines "popular" here? We can always see exactly how our feed is
defined by pressing the `e` key. Doing so brings up the current _feeddef_; a
program in DSL that defines which items are allowed in the feed. In this case,
we see that we're only allowing items from the last 24 hours with more than 5
comments.

Try changing the minimum number of comments to 100, then save and exit `vim`.
After a second or two, you should see the feed update to show a much smaller
subset of those items, reflecting the new feeddef you just edited. You can
always go back to the previous feed by pressing `q`.

Note that each of these items represents the linked page itself --- if you
press `p`, you should see the underlying article rendered in
`private/printed.pdf`. But, we know that HN posts have associated discussions.

To access those discussions, select the story you are interested in and press
`c`. You should now see a list of HN discussions about that URL (this works
even if you start from a non-HN-related feed, but those are less likely to have
such discussions). On each of those discussions, you can either `p`rint the HN
discussion page as a PDF, or press `return` to show each comment as its own
item in a new feed from within Audrey3.

#### Error Messages
Fair warning, I don't have any good handler for error messages right now. So it
just crashes. What's worse, `charterm` seems to put the terminal in a different
mode, so the error messages are not printed nicely.
