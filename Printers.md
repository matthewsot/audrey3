# Adding New Printers
A printer is a function that takes an item and either renders it to a file (in
the example printer, `private/printed.pdf`) and returns `#t`, or it returns
`#f`. Printers are called in a user-defined order until one returns `#t`.

Currently, the only printer I have uploaded is the `webpage.rkt` printer. It
just calls `wkhtmltopdf` to render the website to PDF.

New printers can be added by implementing the print function, then adding the
print function to the list curried onto `try-print-item` in `example.rkt`. Make
sure to add it to the beginning of the list to take priority over the default
printer.

I've had some reasonable results using the following pattern, if you're trying
to print extra-nicely from a relatively stable site with few/no pictures:
1. Download the HTML.
2. Use `pandoc` to convert the HTML to the Pandoc `markdown` format, like
   `pandoc -f html -t markdown`.
3. Use Racket's `regexp-match` to strip the markdown file to just the main
   content of the article.
4. Use `pandoc` to convert the stripped-down markdown to `pdf` format via
   LaTeX, like `pandoc -f markdown -t latex -o private/printed.pdf`.

This step is probably the most security-problematic, as you're shuffling
untrusted content around shell scripts and such. It's probably a good idea to
keep that in mind.
