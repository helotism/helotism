---
layout: presentation_v0.6.0
title: "Configuration Management"
excerpt: "GitHub and Saltstack"
author: "Christian Prior"
dummycontent: false
theme: solarized
---




<section style="text-align: center;">
<h2>Slides available</h2>
<p><a href="{{ "/business/marketing/presentation/configuration-management-with-GitHub-and-Saltstack" | prepend: site.baseurl }}" >
http://www.helotism.de \ ⏎<br />
/business/marketing/presentation/ \ ⏎<br />
configuration-management-with-GitHub-and-Saltstack
</a></p>
</section>



<section data-markdown>
<script type="text/template">
<h2>Content</h2>

| domain        | logical           | physical  |
| ------------- |:-------------:| -----:|
| business | Config Mgt | ITIL |
| technology | sensor; actor | Raspberry Pi |
| application | version control; OSS with Config Mgt | Saltstack, Git, GitHub | 
| data | | state files |

<del>Monitoring; LogManagement</del>
</script>
</section>



<section>


<section data-markdown data-domain="business">
## Configuration Management ##
![]({{ "/application/logical/images/configuration-management_BH.svg" | prepend: site.baseurl }})

<sub><sup>Configuration Management Principles and Practice; Anne Mette Hass, Glenn Hass; Addison Wesley 2003</sup></sub>
</section>


<section data-markdown data-domain="business">
## Cfg Mgt and ITIL ##

- Service Asset and Configuration Management
- In Service Transition interdependency between Knowledge Management and SACM
  - think "known error database" which _must_ match against complex attributes
- "Configuration management is the management and traceability of every aspect of a configuration from beginning to end" (Wikipedia)

</section>


<section data-markdown data-domain="business">
## ITIL process map ##

| input from | output to |
|------------|------------|
| Change Management                  | Change Management              |
| Release & Deployment Mgt           | Change Evaluation              |
| Service Validation and Testing     | Project Management             |
| Knowledge Management               | Release & Deployment Mgt       |
|                                    | Service Validation and Testing |
|                                    | Knowledge Management           |

[it-processmaps.com](http://wiki.en.it-processmaps.com/index.php/Service_Asset_and_Configuration_Management)

</section>


<section data-markdown data-domain="business">
->[serview.de process map](https://www.serview.de/fileadmin/redakteur/medien/downloads/poster/poster_process_map_itil.pdf)
</section>


</section>





<section>


<section data-domain="technology">
<h2>Development Boards: Common Features</h2>
<img src="{{ "/technology/physical/raspberry-pi/rpi-major-features.svg" | prepend: site.baseurl }}" alt="boards" width="30%" style="float: right">
<ul style="width: 60%;">
<li>Computation: Processor and Memory       </li>
<li>Communication through Ethernet/WiFi/BT/…        </li>
<li>Powersupply: Consumption, buttons       </li>
<li>Interaction via GPIO                    </li>
<li>Fixture: Mounting holes and dimensions  </li>
<li>Storage: SD cards and beyond            </li>
<li>Synchronization: RTC time               </li>
</ul>
</section>


<section data-domain="technology">
<h2>Typical sensors and actors</h2>
<ul style="width: 30%;" style="float: right">
<li>LED                          </li>
<li>RGB LED                    </li>
<li>Servo Motor                  </li>
<li>Buzzer                       </li>
<li>Stepper Motor                </li>
<li>LCD Display                  </li>
<li>...                          </li>
</ul>
<ul style="width: 30%;" style="float: right">
<li>Button                       </li>
<li>Line Sensor                  </li>
<li>Light Sensor                 </li>
<li>Distance Sensor              </li>
<li>Motion Sensor/Gyro           </li>
<li>Temperature Probe            </li>
<li>...                          </li>
</ul>
</section>



</section>





<section>


<section style="text-align: center;" data-domain="application">
<h2>Typical Usecase Revision Control</h2>
<p>Source Code repository with branches and merges</p>
<div>
<ul class="gallery" data-interval="3" data-iterations="0" style="width: 640px; height: 360px; margin: 0px;">
    <li style="width: 640px; height: 360px; margin: 0px;"><img width="600" height="300" style="border: none; width: 600px; margin: 0px; height: 300px; top: 20px;" src="{{ "/application/physical/images/git-basic-branching-merging_Figure_3-10_A-simple-commit-history.png" | prepend: site.baseurl }}" alt="A simple commit history"></li>
    <li style="width: 640px; height: 360px; margin: 0px;"><img width="600" height="300" style="border: none; width: 600px; margin: 0px; height: 300px; top: 20px;" src="{{ "/application/physical/images/git-basic-branching-merging_Figure_3-11_Creating-a-new-branch-pointer.png" | prepend: site.baseurl }}" alt="Creating a new branch pointer"></li>
    <li style="width: 640px; height: 360px; margin: 0px;"><img width="600" height="300" style="border: none; width: 600px; margin: 0px; height: 300px; top: 20px;" src="{{ "/application/physical/images/git-basic-branching-merging_Figure_3-12_The-issue-branch-has-moved-forward-with-your-work.png" | prepend: site.baseurl }}" alt="The issue branch has moved forward"></li>
    <li style="width: 640px; height: 360px; margin: 0px;"><img width="600" height="300" style="border: none; width: 600px; margin: 0px; height: 300px; top: 20px;" src="{{ "/application/physical/images/git-basic-branching-merging_Figure_3-13_Hotfix-branch-based-on-master.png" | prepend: site.baseurl }}" alt="Hotfix branch based on master"></li>
    <li style="width: 640px; height: 360px; margin: 0px;"><img width="600" height="300" style="border: none; width: 600px; margin: 0px; height: 300px; top: 20px;" src="{{ "/application/physical/images/git-basic-branching-merging_Figure_3-14_master-is-fast-forwarded-to-hotfix.png" | prepend: site.baseurl }}" alt="master is fast forwarded to hotfix"></li>
    <li style="width: 640px; height: 360px; margin: 0px;"><img width="600" height="300" style="border: none; width: 600px; margin: 0px; height: 300px; top: 20px;" src="{{ "/application/physical/images/git-basic-branching-merging_Figure_3-15_Work-continues-on-issue.png" | prepend: site.baseurl }}" alt="Work continues on issue"></li>
    <li style="width: 640px; height: 360px; margin: 0px;"><img width="600" height="300" style="border: none; width: 600px; margin: 0px; height: 300px; top: 20px;" src="{{ "/application/physical/images/git-basic-branching-merging_Figure_3-16_Three-snapshots-used-in-a-typical-merge.png" | prepend: site.baseurl }}" alt="Three snapshots used in a typical merge"></li>
    <li style="width: 640px; height: 360px; margin: 0px;"><img width="600" height="300" style="border: none; width: 600px; margin: 0px; height: 300px; top: 20px;" src="{{ "/application/physical/images/git-basic-branching-merging_Figure_3-17_A-merge-commit.png" | prepend: site.baseurl }}" alt="A merge commit"></li>
</ul>
</div>
</section>


<section data-domain="application">
<h2>Popular Cfg Mgt Software</h2>
<img src="{{ "/application/physical/images/OS-cfgmgt_logos_Ansible-Chef-Puppet-Saltstack.svg" | prepend: site.baseurl }}">
</section>


<!-- http://bgrins.github.io/TinyColor/ -->
<section tagcloud data-state="" data-domain="application">
<h2>Typical Scope of Solutions</h2>
    <span tagcloud-color="#859900" tagcloud-link="#" tagcloud-weight="100">[Remote Execution] </span>
    <span tagcloud-color="#aac300" tagcloud-link="#" tagcloud-weight="50">Software Installation </span>
    <span tagcloud-color="#859900" tagcloud-link="#" tagcloud-weight="80">Targeting </span>
    <span tagcloud-color="#b58900" tagcloud-link="#" tagcloud-weight="100">[Cfg Mgt] </span>
    <span tagcloud-color="#dfa900" tagcloud-link="#" tagcloud-weight="50">Defined State </span>
    <span tagcloud-color="#604900" tagcloud-link="#" tagcloud-weight="70">Idempotence </span>
    <span tagcloud-color="#604900" tagcloud-link="#" tagcloud-weight="60">File Management </span>
    <span tagcloud-color="#dfa900" tagcloud-link="#" tagcloud-weight="40">Confidential Data </span>
    <span tagcloud-color="#dc322f" tagcloud-link="#" tagcloud-weight="100">[Event-Driven Infrastructure] </span>
    <span tagcloud-color="#b12826" tagcloud-link="#" tagcloud-weight="40">Presence of Remote Systems </span>
    <span tagcloud-color="#871f1d" tagcloud-link="#" tagcloud-weight="60">React to Monitored State Changes </span>
    <span tagcloud-color="#268bd2" tagcloud-link="#" tagcloud-weight="100">[Documentation] </span>
    <span tagcloud-color="#268bd2" tagcloud-link="#" tagcloud-weight="50">Auditing </span>
</section>


<section data-domain="application">
<h2>Name Clash</h2>
<p>Config Management is _not_ necessarily based on the Develoment Repository.</p>
<img src="{{ "/application/physical/images/cfg-mgt-repo_vs_dev-repo.svg" | prepend: site.baseurl }}">
</section>


<section data-markdown data-domain="application">
##SaltStack Ecosystem
![]({{ "/application/physical/images/saltstack-ecosystem.svg" | prepend: site.baseurl }})
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
  - file:///root/third      #local

env_order: ['pilot', 'production', 'testlab', 'exhibition']
```

- these are powerful configuration mechanisms: "infrastructure as code" served from a Git repo

- many ways to segment or override

</section>



</section>







<section>

<section data-markdown data-domain="application">
## The Demo Setup ##
![]({{ "/application/physical/images/oscfgmgt_demo-setup.svg" | prepend: site.baseurl }})
</section>

</section>


