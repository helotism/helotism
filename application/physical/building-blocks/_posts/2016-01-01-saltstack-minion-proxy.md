---
layout: post
title:  "Saltstack Proxy Minion"
date:   2099-02-07 03:43:24 +0100
categories: [ application-physical_building-blocks ]
---

```Python
def ping():
    '''
    Is the REST server up?
    '''
    r = salt.utils.http.query(DETAILS['url']+'ping', decode_type='json', decode=True)
    try:
        return r['dict'].get('ret', False)
    except Exception:
        return False
```

https://docs.saltstack.com/en/latest/topics/proxyminion/index.html


