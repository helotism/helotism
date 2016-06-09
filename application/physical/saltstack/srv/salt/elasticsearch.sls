jdk7:
  cmd.run:
    - name: 'jre7=$( pacman -Qs "jre7-openjdk-headless" | grep -ic "jre7-openjdk-headless"); if [ ${jre7} -eq 0 ]; then pacman -S --noconfirm --asdeps jre7-openjdk-headless; fi'
    - require_in:
      - pkg: elasticsearch

install elasticsearch:
  pkg.installed:
    - name: elasticsearch
  service.running:
    - name: elasticsearch
    - watch:
      - pkg: elasticsearch
      - file: /etc/elasticsearch/elasticsearch.yml
    - require:
      - pkg: elasticsearch
      - file: /etc/elasticsearch/elasticsearch.yml

basic elasticsearch config:
  file.managed:
    - name: /etc/elasticsearch/elasticsearch.yml
    - contents:
      - "cluster.name: helotism"
      - "node.name: {{ grains['id'] }}"
      - "node.master: true"
      - "#index.number_of_shards: 2"
      - "#index.number_of_replicas: 1"
      - "#network.host: [{{ grains['ip4_interfaces']['lan0'][0] }}, _local_]"
      - 'network.host: [_lan0_, _local_]'
      - 'network.publish_host: _lan0_'
      - 'discovery.zen.ping.unicast.hosts: ["axle", "spoke01", "spoke02"]'
      - "#"
      - "#"

elasticsearch head plugin:
  cmd.run:
    - name: 'eshead=$( elasticsearch-plugin list | grep -ic head); if [ ${eshead} -eq 0 ]; then elasticsearch-plugin install mobz/elasticsearch-head; fi'
    - require:
      - service: elasticsearch
