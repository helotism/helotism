---
layout: presentation_v0.5.0
title: "15 minutes from 0 to RPi cluster"
excerpt: "2016-06-11 @ Pi and More, Trier"
author: "Christian Prior"
dummycontent: false
theme: solarized
---

<section>

<section style="text-align: center;">
<h2>Slides available</h2>
<p><a href="{{ "/business/marketing/presentation/piandmore_2016-06-11" | prepend: "http://www.helotism.de" }}" >
http://www.helotism.de \ ⏎<br />
/business/marketing/presentation/piandmore_2016-06-11
</a></p>
</section>

<section data-markdown>
## This talk

Fast-forward through an installation

Connect to an elasticsearch cluster

</section>

<section data-markdown>
## about me
business administration guy

20 years of Linux enthusiasm

Currently working as a Backlevel Software Support Engineer for a retail solution

/me &#x1F49E; complexity!

https://github.com/cprior

</section>

</section>


<section>

<section data-markdown>
## Helotism ##

https://github.com/helotism/helotism

Installer script for a 250€-cluster solving basic sysadmin requirements

![]({{ "/business/marketing/images/helotism-scope.png" | prepend: site.baseurl }})
</section>

<section data-domain="technology">
<h2>Bill of Materials</h2>
<link rel="stylesheet" type="text/css" href="/business/marketing/website/assets/DataTables/datatables.min.css"/>

<script src="{{ "/business/marketing/website/assets/DataTables/datatables.min.js" | prepend: site.baseurl }}"></script>
<script src="{{ "/business/marketing/website/assets/js/d3.v3.min.js" | prepend: site.baseurl }}"></script>

<script>


$(document).ready(function() {
    d3.text('{{ "/technology/physical/bill-of-materials.csv" | prepend: site.baseurl }}', function (datasetText) {
  var rows = d3.csv.parseRows(datasetText, function(d,i) {
    console.log(d);
    if (i == 0) { var r = ["count", "name", "price"]; }
    else if (d[1].substring(0,4) == "2016") {var r = [d[3] + " " + d[4], d[2], d[10] + " " + d[11]]; }
    console.log(r);
    return r;
  });

  var tbl = d3.select("#bomcontainer")
    .append("table")
    .attr("class", "display")
    .attr("id","tableID");


// headers
  tbl.append("thead").append("tr")
    .selectAll("th")
    .data(rows[0])
    .enter().append("th")
    .text(function(d) {
        return d;
    });

   // data
    tbl.append("tbody")
    .selectAll("tr").data(rows.slice(1))
    .enter().append("tr")

//            { targets: [1,2,10,11], visible: true},
    .selectAll("td")
    .data(function(d){return d;})
    .enter().append("td")
    .text(function(d){return d;})
        $('#tableID').dataTable( {
//        scrollY: "350px",
//        scrollCollapse: true,
        paging: true,
        pageLength: 4,
        pagingType: "simple_numbers",
        responsive: false,
        iDisplayLength: 4,
        lengthMenu: [ 2, 4, 6, 8 ],
        columnDefs: [
            { targets: '_all', visible: true }
        ]
        } );
    });
});

</script>
<div id="bomcontainer"></div>

</section>


</section>


<section>

<section data-markdown>
## Bootstrap script ##

![]({{ "/application/physical/images/customization-workflow.png" | prepend: site.baseurl }})
</section>

<section data-markdown>
## Basic config items ##

| variable name |  getopts parameter |
|---------------|------------|
| __GITREMOTEORIGINURL | -r |
| __GITREMOTEORIGINBRANCH |  -g |
| __COUNT | -c |
| __MASTERHOSTNAME |  -m |
| __HOSTNAMEPREFIX |  -n |
| __NETWORKSEGMENTCIDR |  -s |
| __FQDNNAME |  -d |
</section>

<section data-markdown>
## Inner workings ##

| getopts | default |
|----------------|---------|
| -r |  https://github.com/helotism/helotism.git |
| -g |  master  |
| -c |  2 |
| -m |  axle |
| -n |  spoke0 |
| -s |  10.16.6.1/24 |
| -d |  wheel.example.com |
| -b |  /dev/null |
</section>

</section>


<section>

<section data-markdown data-domain="technology">
##Powersupply

- prevent brown-out
- one switch for all boards

</section>

<section data-markdown data-domain="technology">
##Power Consumption

Rule of thumb:

- 1 Pi idle == 2.5W (5V * 0,5 A)
- 1 Pi under load, no USB == 5W (5V * 1 A)

Caveat: GPIO-pins are no USB ports ;)
- 5V passed straight through from USB
- 3.3V rail max 50mA
- GPIO pins 16ma in total

</section>


<section data-markdown data-domain="technology">
##On-Off-Switch


- hardware
- code

![]({{ "/technology/physical/myrack-v0.5/circuit/helotism_powersupply_bb_640x312.png" | prepend: site.baseurl }})

[raspberry-pi-geek.com On-Off-Switch](http://www.raspberry-pi-geek.com/Archive/2013/01/Adding-an-On-Off-switch-to-your-Raspberry-Pi "Adding an On/Off switch to your Raspberry Pi")

</section>

<section data-markdown data-domain="technology">
##Noise
![]({{ "/technology/logical/images/ElectricalWireNoise.png" | prepend: site.baseurl }})
</section>

<section data-markdown data-domain="technology">
##Discretization
![]({{ "/technology/logical/images/ElectricalDiscretization.png" | prepend: site.baseurl }})
</section>

<section data-markdown data-domain="technology">
##Debouncing
![]({{ "/technology/logical/images/ElectricalSwitchDebounce.png" | prepend: site.baseurl }})
</section>

<section data-markdown data-domain="technology">
##Python logic…

```Python
def handleInterrupt(args):
    button20.pressed = True #that's a fact, but...
    button20.pressed_debounced = False
    interrupted_at = datetime.datetime.now()
    debounce_until = interrupted_at + datetime.timedelta(0,3)

    while True:
      if (datetime.datetime.now() > debounce_until):
          journal.send('GPIO20 pressed DEBOUNCED.', FIELD2='GPIO20')
          //do something
          button20.pressed_debounced = True
          return
      else:
          journal.send('GPIO20 pressed, not debounced', FIELD2='GPIO20')
      time.sleep(0.5) #inside this interrupt handler only
```
</section>


<section data-markdown data-domain="technology">
##…and systemd daemonization.

```INI
[Unit]
Description=An GPIO interrupt listener
After=local-fs.target

[Service]
Type=simple
ExecStart=/bin/bash -c 'cd /opt/helotism/powersupply-env; \
                        source bin/activate; \
                        python ./mraa_interrupt.py'

[Install]
WantedBy=multi-user.target
```
</section>

</section>


<!-- application                                   -->

<section>

<section data-markdown data-domain="application">
##SaltStack Ecosystem
![]({{ "/application/physical/images/saltstack-ecosystem.png" | prepend: site.baseurl }})
</section>

<section data-markdown data-domain="application">

##SaltStack top file

```YAML
base:          # environment
  'web*':      # targeted minions
    - apache   # state file 'apache.sls'
```

- the top.sls is a special state file as "entry point" into the fileserver

- "apache" references ```./apache.sls``` file

</section>

<section data-markdown data-domain="application">

##SaltStack state file

```YAML
#apache.sls
{% raw %}{% if grains['os'] == 'Debian' %}
apache: apache2
{% elif grains['os'] == 'RedHat' %}
apache: httpd
{% endif %}{% endraw %}
```

- Jinja2 template language

- one should read the fine manual: http://jinja.pocoo.org/docs/dev/

</section>

<section data-markdown data-domain="application">

##SaltStack environments

```YAML
file_roots:
  dev:
    - /srv/salt/dev
  base:
    - /srv/salt
```

- environments are configured in the master config file

</section>

<section data-markdown data-domain="application">
##SaltStack fileserver
```YAML
fileserver_backend: #first filename match wins
  - roots
  - git

gitfs_remotes:
  - git://github.com/example/first.git
  - https://github.com/example/second.git
    - root: salt            #subdirectory
    - mountpoint: salt://sub/dir
    - base: myTag05         #git branch
  - file:///root/third

#top_file_merging_strategy: merge #same
#env_order: ['base', 'dev', 'prod']
```

- these are powerful configuration mechanisms: "infrastructure as code" served from a Git repo

- many ways to segment or override

</section>

<section data-markdown data-domain="application">
##Sample Salt Usage

```bash
#remote execution?
salt '*' cmd.run 'uname -a'
```

```bash
#listing and accepting keys
salt-key -L
salt-key -A
```

```bash
#salt.modules.test.ping
salt '*' test.ping
```

```bash
#targeting by grains
salt -G 'os:(RedHat|Debian)' test.ping
```

```bash
#more sound than test.ping
salt-run manage.up
```

```bash
#apply common.sls on all (accepted) minions
salt '*' state.sls common
#This is the "endgame" in salt
salt '*' state.highstate
#remote execution!
salt '*' cmd.run 'uname -a'
```

</section>

</section>




<section>
<section data-markdown data-domain="technology">
##Demo

…
</section>
</section>

<section>
<section data-markdown data-domain="technology">
##Questions?

Fork it on GitHub!

Issues welcome.

</section>
</section>




