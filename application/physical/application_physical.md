---
layout: default
title: Logical Application
---

If your life in system administration is like my life, then it is a liberating experience to learn to use the first configuration management software. Especially for the hobbyist (power-)user the complexity of a networked installation of server, clients and services can be daunting -- when you imagine to walk away from it for a few months because of other hobbies.

And the seasoned IT professional in or close to operations is well advised to spend time with at least one of the existing open source tools, if he hasn't encountered configuration management in his daily job.

There are four major open source configuration management software: Puppet, Chef, Ansible and SaltStack. Each has its own profile with strengths and weaknesses. The Helotism project uses SaltStack because it does. [https://en.wikipedia.org/wiki/Comparison_of_open-source_configuration_management_software](https://en.wikipedia.org/wiki/Comparison_of_open-source_configuration_management_software) lists many more alternatives.

## Some Useful Principles ##

With a vocabulary of up to 2000 words a person may already get along quite well in daily life; someone with an speaking vocabulary in the high four-digits is quite eloquent and a skilled writer may command above 50,000 words. A living language has several million words.

To have a grasp of the concepts behind a few such *special terms* is helpful when dealing with automation.

[https://en.wikipedia.org/wiki/Idempotence](https://en.wikipedia.org/wiki/Idempotence#Computer_science_meaning)

[https://en.wikipedia.org/wiki/Finite-state_machine](https://en.wikipedia.org/wiki/Finite-state_machine)

A state machine is commonly found in firmware programming but certainly deserves much wider application: A (relatively small) number of system states is defined beforehand and the program provides mechanisms from one (some) state into an other.

To apply a simplyfied state machine language to the availability of the terminal multiplexer `screen` on a computer the two states **installed** and **not installed** may be defined. The mechanism to achieve these states are on Gentoo `emerge app-misc/screen` and `emerge --unmerge app-misc/screen`.

Any configuration management with idempotence will not download/compile(?)/install/configure `screen` more than once, even if it issued its transition to **installed** more than once.

Configuration management can conceptually be thought of as a state machine across many systems.

They abstract away the differences between various distributions, so `pkg.installed` in SaltStack will deal with either `emerge app-misc/screen` or `apt-get install screen` or man more.

An added layer of individual host/node/client configuration like an own hostname for 127.0.0.1 in `/etc/hosts` makes these approaches very powerful.

On top of that configuration managment typicaly not just deals with such software distribution but gathers informational snippets from the connected sysmtems, like the serial number of the hard drive.

Even the most complex setups are no longer buried in several `.bash_history` files or even paper-based machine-logbooks.