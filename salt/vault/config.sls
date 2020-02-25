{% from 'vault/map.jinja' import vault with context %}

include:
    - .


{% for name, policy in vault.get('policies', {}).items() %}
vault-policy-{{ name }}:
    mdl_vault.policy_present:
        - name: {{ name }}
        - rules: '{{ policy | json }}'
{% endfor %}


{% for name in vault.get('policies.absent', []) %}
vault-absent-policy-{{ name }}:
    mdl_vault.policy_absent:
        - name: {{ name }}
{% endfor %}


{% for audit in vault.get('audit', []) %}
vault-audit-{{ audit.get('backend_name', audit.backend_type) }}:
    mdl_vault.audit_backend_enabled:
        - backend_type: {{ audit.backend_type }}
        - backend_name: {{ audit.get('backend_name', '~') }}
        - description: {{ audit.get('description', '~') }}
{% endfor %}


{% for auth_backend in vault.get('auth_backends', []) %}
vault-auth-backend-{{ auth_backend.get('mount_point', auth_backend.backend_type) }}:
    mdl_vault.auth_backend_enabled:
        - backend_type: {{ auth_backend.backend_type }}
        - mount_point: {{ auth_backend.get('mount_point', '~') }}
        - description: {{ auth_backend.get('description', '~') }}
{% endfor %}
