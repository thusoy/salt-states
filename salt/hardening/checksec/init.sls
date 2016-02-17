hardening-checksec:
  file.managed:
    - name: /usr/bin/checksec
    - source: salt://hardening/checksec/checksec.sh
    - mode: 755
