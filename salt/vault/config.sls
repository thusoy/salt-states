{% from 'vault/map.jinja' import vault with context %}

include:
    - .


{% for name, policy in vault.get('policies', {}).items() %}
vault-config-policy-{{ name }}:
    mdl_vault.policy_present:
        - name: {{ name }}
        - rules: '{{ policy | json }}'
{% endfor %}


{% for name in vault.get('policies.absent', []) %}
vault-config-absent-policy-{{ name }}:
    mdl_vault.policy_absent:
        - name: {{ name }}
{% endfor %}


{% for audit in vault.get('audit', []) %}
vault-config-audit-{{ audit.get('backend_name', audit.backend_type) }}:
    mdl_vault.audit_backend_enabled:
        - backend_type: {{ audit.backend_type }}
        - backend_name: {{ audit.get('backend_name', '~') }}
        - description: {{ audit.get('description', '~') }}
{% endfor %}


{% for auth_backend in vault.get('auth_backends', []) %}
{% set mount_point = auth_backend.get('mount_point', auth_backend.backend_type) %}
vault-config-auth-backend-{{ mount_point }}:
    mdl_vault.auth_backend_enabled:
        - backend_type: {{ auth_backend.backend_type }}
        - mount_point: {{ auth_backend.get('mount_point', '~') }}
        - description: {{ auth_backend.get('description', '~') }}


{% if 'config' in auth_backend %}
vault-config-auth-backend-config-{{ mount_point }}:
    mdl_vault.auth_backend_configured:
        - mount_point: {{ mount_point }}
        - config: {{ auth_backend.config | json }}
        - require:
            - mdl_vault: vault-config-auth-backend-{{ mount_point }}
{% endif %}

{% endfor %}
