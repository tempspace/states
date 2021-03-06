include:
  - git
  - virtualenv
  - nrpe

/etc/diamond/collectors:
  file:
    - directory
    - user: root
    - group: root
    - mode: 550
    - require:
      - file: diamond

diamond_upstart:
  file:
    - managed
    - name: /etc/init/diamond.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://diamond/upstart.jinja2

diamond_requirements:
  file:
    - managed
    - name: /usr/local/diamond/salt-requirements.txt
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://diamond/requirements.jinja2
    - require:
      - virtualenv: diamond

/etc/diamond/collectors/ProcessMemoryCollector.conf:
  file:
    - absent

diamond:
  virtualenv:
    - manage
    - upgrade: True
    - name: /usr/local/diamond
    - require:
      - pkg: python-virtualenv
  module:
    - wait
    - name: pip.install
    - upgrade: True
    - pkgs: ''
    - bin_env: /usr/local/diamond
    - requirements: /usr/local/diamond/salt-requirements.txt
    - require:
      - pkg: git
      - pkg: python-virtualenv
      - file: diamond_upstart
    - watch:
      - file: diamond_requirements
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
  file:
    - managed
    - name: /etc/diamond/diamond.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://diamond/config.jinja2
    - require:
      - virtualenv: diamond
  service:
    - running
    - enable: True
    - watch:
      - virtualenv: diamond
      - file: diamond
      - file: diamond_upstart
      - module: diamond
      - cmd: diamond
  cmd:
    - wait
    - name: find /usr/local/diamond -name '*.pyc' -delete
    - stateful: False
    - watch:
      - module: diamond

/etc/diamond/collectors/ProcessResourcesCollector.conf:
  file:
    - managed
    - template: jinja
    - source: salt://diamond/ProcessResourcesCollector.jinja2
    - user: root
    - group: root
    - mode: 440
    - require:
      - file: /etc/diamond/collectors
      - file: /etc/diamond/collectors/ProcessMemoryCollector.conf

{#
archive of installation trough debian package

diamond:
  pkg:
    - installed
  file.managed:
    - name: /etc/diamond/diamond.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - source: salt://diamond/config.jinja2
    - require:
      - pkg: diamond
  service:
    - running
    - watch:
      - pkg: diamond
      - file: /etc/diamond/diamond.conf
#}

/etc/nagios/nrpe.d/diamond.cfg:
  file.managed:
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://diamond/nrpe.jinja2

extend:
  nagios-nrpe-server:
    service:
      - watch:
        - file: /etc/nagios/nrpe.d/diamond.cfg
