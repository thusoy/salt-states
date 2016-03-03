# Annoying error logging that always causes stderr output,
# introduced by https://github.com/saltstack/salt/pull/29148
# and resolved by https://github.com/saltstack/salt/pull/31207

include:
    - patches


{% if '2015.8.3' <= grains.saltversion < '2015.8.8' %}
remove-boto_route53-error-logging:
    patch.apply:
        - name: /usr/lib/python2.7/dist-packages/salt/modules/boto_route53.py
        - hash: sha256=5d1ce461949675160382502ec5d6a5748a957ba114235f7ead9413ab0184669c
        - patch: |
            61a62,63
            > REQUIRED_BOTO_VERSION = '2.35.0'
            >
            68,71c70
            <     required_boto_version = '2.35.0'
            <     if _LooseVersion(boto.__version__) < _LooseVersion(required_boto_version):
            <         msg = 'boto_route53 requires at least boto {0}.'.format(required_boto_version)
            <         log.error(msg)
            ---
            >     if _LooseVersion(boto.__version__) < _LooseVersion(REQUIRED_BOTO_VERSION):
            84c83,85
            <         return False
            ---
            >         msg = ('A boto library with version at least {0} was not '
            >                'found').format(REQUIRED_BOTO_VERSION)
            >         return (False, msg)

{% endif %}
