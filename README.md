# Audrey3
A Racket program for managing _feeds_: finite lists of _items_ that may change
over time.

#### More Details
1. [Design Goals](Goals.md)
2. [Usage of Example Config](Usage.md)
3. [Configuring the UI](UI.md)
4. [Adding New Sources](Sources.md)
5. [Adding New Printers](Printers.md)

#### Security Note
Audrey3 will download information from the Internet. Some of Audrey3's
operations will execute code and/or make network requests based on this
information. For example, printing an item may call `wkhtmltopdf` with that
item's `url` attribute. We don't currently do any serious sanitization (e.g.,
that `url` might actually be an arbitrary, long bytestring). This is probably a
bad idea, so please be cognizant of this especially when interacting with
untrusted sources.

#### Credits
I decided to work out this idea while learning Racket from the C311
(Programming Languages) course hosted by Dan Friedman + Weixi Ma. I am grateful
for the invitation to audit their course, and happily credit them with any good
practices in this code while taking full responsibility on myself for any
rookie mistakes!

The idea of abstracting filters to get a tight over-approximation of the
required items is a naive implementation of the idea of _symbolic abstraction_,
which I was introduced to by Aditya Thakur's
[thesis](http://thakur.cs.ucdavis.edu/bibliography/thakur_PHD14.html) and ECS
240 (Programming Languages) course.

As discussed in the `License` section below, the code in `audrey3/charterm` is
taken from the wonderful Racket charterm package.

[The name](https://www.youtube.com/watch?v=L7SkrYF8lCU).

#### Disclaimer
Any content sources (RSS feeds, discussion providers, etc.) used in the example
configuration is provided purely for expository purposes. I am making no
endorsement of any such organizations. But I hope they give some idea of how to
read information in from a few different formats.

#### License
Except where mentioned below, all code in this repository is licensed under the
AGPLv3, no later versions. See [LICENSE](LICENSE) for a copy of this license.

**NOTE:** The files in [`audrey3/charterm`](audrey3/charterm) are a slightly
modified version of the racket-charterm package.  They (including any changes I
have made) are licensed under the LGPLv3.
