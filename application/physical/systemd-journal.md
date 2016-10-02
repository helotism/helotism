---
title: A guide to logging in systemd
layout: default
---


http://thread.gmane.org/gmane.comp.sysutils.systemd.devel/6922/focus=6950

"primarily for your entertainment and education. Thank you!"
https://www.freedesktop.org/wiki/Software/systemd/journal-files/


realtime/monotonic


structure
http://cgit.freedesktop.org/systemd/systemd/tree/src/journal/journal-def.h
https://www.freedesktop.org/wiki/Software/systemd/journal-files/

Export format
https://www.freedesktop.org/wiki/Software/systemd/export/

JSON format



FSS Forwad Secure Sealing
https://plus.google.com/115547683951727699051/posts/g1E6AxVKtyc
https://lwn.net/Articles/512895/
cryptographic seal to detect tampering



https://github.com/systemd/systemd/blob/master/src/journal-remote/journal-upload.c#L435
if (!(host = startswith(url, "http://")) && !(host = startswith(url, "https://"))) {

#define PRIV_KEY_FILE CERTIFICATE_ROOT "/private/journal-upload.pem"
#define CERT_FILE     CERTIFICATE_ROOT "/certs/journal-upload.pem"
#define TRUST_FILE    CERTIFICATE_ROOT "/ca/trusted.pem"
#define DEFAULT_PORT  19532

#define STATE_FILE "/var/lib/systemd/journal-upload/state"

There must be the path existing and the permissions set!
return log_error_errno(r, "Cannot create parent directory of state file %s: %m",

return log_error_errno(r, "Cannot save state to %s: %m",



https://github.com/systemd/systemd/blob/master/src/journal-remote/browse.html
