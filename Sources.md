# Adding New Sources
A source is just a function that takes two arguments and produces a list of
`item`s (which itself is just an association list of attributes). The first
argument is the `filter`, written in a filter DSL. The second is a flag to
indicate whether any available cached copy of the source should be used or if a
new copy should be downloaded.

I will focus most on the `filter` argument, since the latter is more
self-explanatory. In theory, you can ignore the `filter` argument and just
return all of the items from your source. The items you return will be checked
against this filter before being composed to form the feed.

However, this approach of downloading everything and filtering afterwards may
not always be desirable or possible. For example, if your source is "Twitter,"
it would be problematic to first download the entirety of Twitter tweet history
if the user is going to filter it down to just the last week's worth of tweets
from a single user.

The first improvement one may try is to read the provided filter and translate
it into an equivalent form that can be provided to the underlying source
(Twitter API in this hypothetical). This is possible and probably a good idea
if the underlying source has a highly expressive API (e.g., a SQL server).

However, in most cases the API will probably be a lot less expressive than our
filter language. To address this case, the `abstract-filter` method allows for
computing a _sound over-approximation_ of the filter (more specifically, the
_symbolic abstraction_ of the filter --- see "Symbolic Abstraction: Algorithms
and Applications" by Aditya V. Thakur for an overview). The API can then be
queried using this over-approximation to get a much tighter superset of the
desired posts, which can then be filtered down more manageably by Audrey3.

In the Twitter example, given a filter like
```
(or (and (= (attr "handle") "@abc")
         (> (attr "timestamp") 100))
    (and (= (attr "handle") "@def")
         (> (attr "timestamp") 50)))
```
The abstracted version will be
```
(((atr "handle") . (val-in ("@abc" "@def")))
 ((atr "timestamp") . (interval (50 . +inf.0))))
```
So it is safe to query for just the posts from `@abc` and `@def` since
timestamp `50`.

#### Notes About Feed-Items
A feed item is just an association list of attributes. The attribute keys
should always be strings. Some things to keep in mind:
1. Every item is expected to have a `title` attribute.
2. Attribute values should be serializable, unless you do not want the user to
   be able to save the item locally.
3. Some attributes are treated specially by the example configuration. For
   example, if an item has the `action-ui-eval` attribute, then opening that
   item will execute the corresponding attribute value instead of just
   displaying its details in a pager.
4. Attributes with string or number-type values are considered _id_s. These are
   used for identifying items. Two items are considered equal if and only if
   they have the same ID. An item gets a label if and only if the label applies
   to one of its ids.

To understand the last point a bit further, consider a post on Hacker News
linking to a specific webpage, `abc.com/hello`. If you label this post as, say,
`ignore`, does that mean you want to ignore just that specific HN post, or all
future posts about the URL `abc.com/hello`? By saving label-_id_ pairs instead
of label-_item_ pairs, you can make this decision more explicitly. If you
choose to label the, say, `url` id, then it will ignore all future items with
that URL. But if you choose to label the, say, `hn-story-id` id, then it will
only ignore that specific post on HN.

The ids are also used for saving posts. When you save locally some post, it
will first check to be sure that post isn't already saved in your local
database. To do this, it compares the ids so if some post was already saved
with the same exact set of ids, then it is assumed that item was already saved
locally.

In an ideal world, we would probably prefer to pair labels with arbitrary
filters. But that would probably take too long to check, especially after
labelling a large number of items.
