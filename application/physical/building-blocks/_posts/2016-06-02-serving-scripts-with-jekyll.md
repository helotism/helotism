---
layout: post
title:  "Serving scripts with Jekyll and GitHub pages"
date:   2016-06-02 20:00:00 +0100
categories: [ application-physical_building-blocks ]
---

The trick is to use the extension .html instead of .md as the latter wraps the first line in a p paragraph tag.

In such a html file there may be frontmatter, and the tag include_relative tag makes it easy to serve a script from another folder.

```html
{% raw %}
---
title: Bootstrap
---

{% include_relative application/physical/scripts/bootstrap-cluster.sh %}
{% endraw %}
```

Of course this only works for the same branch of the repository but that seems like no real limitation.

The Jekyll plugin for redirections, which is included in the GitHub pages installation, works with JavaScript redirects and cannot be used in the typical workflow with curl or wget.