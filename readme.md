# The Worst Static Site Generator In The World

One of the best thing about static site generators is that they typically run with very few dependencies (and definitely not closed-source GUI frameworks as a dependency).

This static site generator has a *massive* dependency on SwiftUI and can't run without it.

It uses SwiftUI's incremental updates to build a static site (once from scratch) and then observes file changes, only writing the files that need it.
