{% from 'terraform/map.jinja' import terraform with context %}
{% set version, version_hash = terraform.version_spec.split(' ') %}


terraform:
    archive.extracted:
        - name: /usr/local/bin/
        - source: https://releases.hashicorp.com/terraform/{{ version }}/terraform_{{ version }}_linux_amd64.zip
        - source_hash: {{ version_hash }}
        - archive_format: zip
        - enforce_toplevel: False
        - overwrite: True
        - unless:
            - 'CHECKPOINT_DISABLE=1 /usr/local/bin/terraform -version | grep -E "^Terraform v{{ version }}$"'
