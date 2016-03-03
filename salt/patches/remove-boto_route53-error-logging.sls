# Annoying error logging that always causes stderr output,
# introduced by https://github.com/saltstack/salt/pull/29148
# and resolved by https://github.com/saltstack/salt/pull/31207

{% if '2015.8.3' <= grains.saltversion < '2015.8.8' %}
remove-boto_route53-error-logging:
    file.patch:
        - name: /usr/lib/python2.7/dist-packages/salt/modules/boto_route53.py
        - hash: sha256=5d1ce461949675160382502ec5d6a5748a957ba114235f7ead9413ab0184669c
        - source: salt://patches/remove-boto_route53-error-logging.patch
{% endif %}
