# Goals
1. Learn Racket.
2. Write some DSLs.
3. Have an expressive language for defining filters that can be edited from
   within the UI.
4. Handle both infinite feeds (like the HN frontpage or a Twitter feed) and
   disappearing feeds (like an RSS feed that only contains the latest 10
   stories) gracefully.
5. Have a simple data model so that a wide variety of different types of
   'feeds' can be supported from the same interface: latest news articles,
   comments, emails, filesystem listings, moderation queues, etc.

#### Not Goals
1. Speed
2. Rendering article contents nicely within the UI.
