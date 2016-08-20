---
layout: post
title:  "Serving scripts with Jekyll and GitHub pages"
date:   2016-06-02 20:00:00 +0100
categories: [ application-physical_building-blocks ]
abstract: How to make a (bash) script downloadable from GitHub, for easy "bootstrapping".
---

There exists a (dubious) popularity to download scripts with curl and executing them with bash. With a little trickery this even works on GitHub pages.

Two files are needed: The script itself, usually with a file extension .sh, and a .html file including this in raw mode.

The trick with these .html files instead of .md is the latter wraps the first line in a p paragraph tag.

In such a html file there may be frontmatter, and the tag include_relative tag makes it easy to serve a script from another folder.

Here the example of `bootstrap-arch.sh.html` in the root folder of the GitHub repository:

```html
{% raw %}
---
title: Bootstrap
---

{% include_relative application/physical/scripts/bootstrap-arch.sh %}
{% endraw %}
```

Of course this only works for the same branch of the repository but that seems like no real limitation.

The Jekyll plugin for redirections, which is included in the GitHub pages installation, works with JavaScript redirects and cannot be used in the typical workflow with curl or wget (following JaveScript redirects is a browser implementation).
