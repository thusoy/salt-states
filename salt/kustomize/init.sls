{% set kustomize = pillar.get('kustomize', {}) %}
# Get latest release and checksum from the github releases:
# https://github.com/kubernetes-sigs/kustomize/releases
{% set version_spec = kustomize.get('version_spec', '3.6.1 sha256=0aeca6a054183bd8e7c29307875c8162aba6d2d4e170d3e7751aa78660237126') %}
{% set version, version_hash = version_spec.split() %}

kustomize:
    file.managed:
        - name: /usr/local/src/kustomize.tar.gz
        - source: https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv{{ version }}/kustomize_v{{ version }}_linux_amd64.tar.gz
        - source_hash: {{ version_hash }}

    cmd.wait:
        - name: tar xf /usr/local/src/kustomize.tar.gz -C /usr/local/bin
        - watch:
            - file: kustomize
