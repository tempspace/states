include:
  - apt
  - nrpe
  - diamond

pdnsd:
  pkg:
    - installed
    - require:
      - cmd: apt_sources
  debconf:
    - set
    - data:
      'pdnsd/conf': {'type': 'select', 'value': 'Manual'}
    - require:
      - pkg: debconf-utils
  service:
    - running
    - enable: True
    - watch:
      - file: /etc/default/pdnsd
      - file: /etc/pdnsd.conf

/etc/default/pdnsd:
  file:
    - managed
    - require:
      - pkg: pdnsd
    - template: jinja
    - source: salt://pdnsd/init.jinja2
    - user: root
    - group: root
    - mode: 440

/etc/pdnsd.conf:
  file:
    - managed
    - require:
      - pkg: pdnsd
    - template: jinja
    - source: salt://pdnsd/config.jinja2
    - user: root
    - group: root
    - mode: 440
    - context: {{ pillar['dns_proxy'] }}

pdsnd_diamond_memory:
  file:
    - accumulated
    - name: processes
    - filename: /etc/diamond/collectors/ProcessMemoryCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessMemoryCollector.conf
    - text:
      - |
        [[pdnsd]]
        exe = ^\/usr\/sbin\/pdnsd$

extend:
  diamond:
    service:
      - watch:
        - file: pdsnd_diamond_memory
  nagios-nrpe-server:
    service:
      - watch:
        - file: /etc/nagios/nrpe.d/pdnsd.cfg