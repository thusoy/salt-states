from __future__ import absolute_import

# Based on https://github.com/mitodl/vault-formula/blob/master/_states/vault.py (BSD 3-clause)

import copy
import logging
import os

import salt.config
import salt.syspaths
import salt.utils
import salt.exceptions
from salt.utils.dictdiffer import RecursiveDictDiffer

log = logging.getLogger(__name__)

try:
    import requests
    DEPS_INSTALLED = True
except ImportError:
    log.debug('Unable to import the requests library.')
    DEPS_INSTALLED = False

__all__ = ['initialize']


def __virtual__():
    return DEPS_INSTALLED


def auth_backend_enabled(name, backend_type, description='', mount_point=None):
    """
    Ensure that the named backend has been enabled

    :param name: ID for state definition
    :param backend_type: The type of authentication backend to enable
    :param description: The description to set for the backend
    :param mount_point: The root path at which the backend will be mounted
    :returns: The result of the state execution
    :rtype: dict
    """
    existing_backends = __salt__['mdl_vault.list_auth_backends']()['data']
    setting_dict = {'type': backend_type, 'description': description}
    backend_enabled = False
    ret = {
        'name': name,
        'comment': '',
        'result': '',
        'changes': {},
    }

    for path, settings in __salt__['mdl_vault.list_auth_backends']().get('data', {}).items():
        if (path.strip('/') == mount_point or backend_type and
            settings['type'] == backend_type):
            backend_enabled = True

    if backend_enabled:
        ret['comment'] = ('The {auth_type} backend mounted at {mount} is already'
                          ' enabled.'.format(auth_type=backend_type,
                                             mount=mount_point or backend_type))
        ret['result'] = True
        ret['changes'] = {}
    elif __opts__['test']:
        ret['result'] = None
    else:
        try:
            __salt__['mdl_vault.enable_auth_backend'](backend_type,
                                                  description=description,
                                                  mount_point=mount_point)
            ret['result'] = True
            new_backends = __salt__['mdl_vault.list_auth_backends']()['data']
            ret['changes'] = _dict_diff(existing_backends, new_backends)
        except __utils__['mdl_vault.vault_error']() as e:
            ret['result'] = False
            log.exception(e)
        ret['comment'] = ('The {backend} backend has been successfully mounted at '
                          '{mount}.'.format(backend=backend_type,
                                            mount=mount_point))
    return ret


def auth_backend_configured(name, mount_point, config):
    """
    Configure the given, already enabled, backend.

    :param name: ID for state definition
    :param mount_point: The mount point of the backend
    :param config: Dictionary with the config values to set.
    """
    ret = {
        'name': name,
        'comment': '',
        'result': True,
        'changes': {},
    }
    existing_config = __salt__['mdl_vault.get_auth_backend_config'](mount_point)['data']
    needs_update = True
    if existing_config:
        # This can't detect all types of changes, if you're removing a value with the
        # intention of reverting to the default you have to explicitly set it back to the
        # default for vault to pick up the changes.
        needs_update = any(existing_config[key] != val for key, val in config.items())

    if not needs_update:
        ret['comment'] = 'Auth backend {0} is already configured'.format(mount_point)
    elif __opts__['test']:
        ret['result'] = None
    elif existing_config is None:
        try:
            __salt__['mdl_vault.configure_auth_backend'](mount_point, config)
        except __utils__['mdl_vault.vault_error']() as e:
            log.exception(error)
            ret['result'] = False
            ret['comment'] = 'Failed to add config for auth backend {0}: {1}'.format(
                mount_point, e.errors)
            return ret

        ret['changes']['old'] = {}
        ret['changes']['new'] = config
        ret['comment'] = 'Added config for auth backend {0}'.format(mount_point)
    else:
        try:
            __salt__['mdl_vault.configure_auth_backend'](mount_point, config)
        except __utils__['mdl_vault.vault_error']() as e:
            log.exception(error)
            ret['result'] = False
            ret['comment'] = 'Failed to modify config for auth backend {0}: {1}'.format(
                mount_point, e.errors)
            return ret

        new_config = __salt__['mdl_vault.get_auth_backend_config'](mount_point)['data']
        ret['changes'] = _dict_diff(existing_config, new_config)
        ret['comment'] = 'Modified config for auth backend {0}'.format(mount_point)

    return ret


def auth_backend_role_present(name, mount_point, config):
    """
    Configure a role for an auth backend that has the /auth/<mount point/role/:name
    endpoint. This includes AWS, Azure, Google Cloud and probably more.

    Config keys can be suffixed with `_pillar` to use the corresponding value from pillar.
    This can be used like
        mdl_vault.auth_backend_role_present:
            - mount_point: gcp
            - name: my-role
            - config:
                type: iam
                bound_service_accounts_pillar:
                    - some_pillar:service_account

    :param name: ID for the state definition and name of the role
    :param mount_point: The mount point of the backend
    :param config: The parameters to configure the role. This will vary between the auth
        backends, see the documentation for details, like
        https://www.vaultproject.io/api-docs/auth/gcp/#parameters-1
    """
    ret = {
        'name': name,
        'comment': '',
        'result': True,
        'changes': {},
    }
    existing_config = __salt__['mdl_vault.get_auth_backend_role'](mount_point, name)
    needs_update = True
    config = _resolve_pillar_keys(config)

    if existing_config:
        existing_config = existing_config['data']
        # This can't detect all types of changes, if you're removing a value with the
        # intention of reverting to the default you have to explicitly set it back to the
        # default for vault to pick up the changes.
        needs_update = any(existing_config[key] != val for key, val in config.items())

    if not needs_update:
        ret['comment'] = 'Auth role {0} for backend {1} is already configured'.format(
            name, mount_point)
    elif __opts__['test']:
        ret['result'] = None
    elif existing_config is None:
        try:
            __salt__['mdl_vault.configure_auth_backend_role'](mount_point, name, config)
        except __utils__['mdl_vault.vault_error']() as e:
            log.exception(error)
            ret['result'] = False
            ret['comment'] = 'Failed to add role {0} for auth backend {1}: {2}'.format(
                name, mount_point, e.errors)
            return ret

        ret['changes']['old'] = {}
        ret['changes']['new'] = config
        ret['comment'] = 'Added config for auth backend {0} role {1}'.format(
            mount_point, name)
    else:
        try:
            __salt__['mdl_vault.configure_auth_backend_role'](mount_point, name, config)
        except __utils__['mdl_vault.vault_error']() as e:
            log.exception(error)
            ret['result'] = False
            ret['comment'] = 'Failed to modify role {0} for auth backend {1}: {2}'.format(
                name, mount_point, e.errors)
            return ret

        new_config = __salt__['mdl_vault.get_auth_backend_role'](mount_point, name)['data']
        ret['changes'] = _dict_diff(existing_config, new_config)
        ret['comment'] = 'Modified role {0} for auth backend {1}'.format(
            name, mount_point)

    return ret


def audit_backend_enabled(name, backend_type, description='', options=None,
                          backend_name=None):
    if not backend_name:
        backend_name = backend_type
    backends = __salt__['mdl_vault.list_audit_backends']().get('data', {})
    setting_dict = {'type': backend_type, 'description': description}
    backend_enabled = False
    ret = {'name': name,
           'comment': '',
           'result': '',
           'changes': {'old': backends}}

    for path, settings in __salt__['mdl_vault.list_audit_backends']().items():
        if (path.strip('/') == backend_type and
            settings['type'] == backend_type):
            backend_enabled = True

    if backend_enabled:
        ret['comment'] = ('The {audit_type} backend is already enabled.'
                          .format(audit_type=backend_type))
        ret['result'] = True
        ret['changes'] = {}
    elif __opts__['test']:
        ret['result'] = None
    else:
        try:
            __salt__['mdl_vault.enable_audit_backend'](backend_type,
                                                   description=description,
                                                   name=backend_name)
            ret['result'] = True
            ret['changes']['new'] = __salt__[
                'mdl_vault.list_audit_backends']()
            ret['comment'] = ('The {backend} audit backend has been '
                              'successfully enabled.'.format(
                                  backend=backend_type))
        except __utils__['mdl_vault.vault_error']() as e:
            ret['result'] = False
            log.exception(e)
    return ret


def secret_backend_enabled(name, backend_type, description='', mount_point=None,
                           connection_config_path=None, connection_config=None,
                           lease_max=None, lease_default=None, ttl_max=None,
                           ttl_default=None, override=False):
    """

    :param name: The ID for the state definition
    :param backend_type: The type of the backend to be enabled (e.g. MySQL)
    :param description: The description to set for the enabled backend
    :param mount_point: The root path for the backend
    :param connection_config_path: The full path to the endpoint used for
                                   configuring the connection (needed for
                                   e.g. Consul)
    :param connection_config: The configuration settings for the backend
                              connection
    :param lease_max: The maximum allowed lease for credentials retrieved from
                      the backend
    :param lease_default: The default allowed lease for credentials retrieved from
                          the backend
    :param ttl_max: The maximum TTL for a lease generated by the backend. Uses
                    the mounts/<mount_point>/tune endpoint.
    :param ttl_default: The default TTL for a lease generated by the backend.
                        Uses the mounts/<mount_point>/tune endpoint.
    :param override: Specifies whether to override the settings for an existing mount
    :returns: The result of the execution
    :rtype: dict

    """
    backends = __salt__['mdl_vault.list_secret_backends']().get('data', {})
    backend_enabled = False
    ret = {'name': name,
           'comment': '',
           'result': '',
           'changes': {'old': backends}}

    for path, settings in __salt__['mdl_vault.list_secret_backends']().get('data', {}).items():
        if (path.strip('/') == mount_point and
            settings['type'] == backend_type):
            backend_enabled = True

    if backend_enabled and not override:
        ret['comment'] = ('The {secret_type} backend mounted at {mount} is already'
                          ' enabled.'.format(secret_type=backend_type,
                                             mount=mount_point))
        ret['result'] = True
    elif __opts__['test']:
        ret['result'] = None
    else:
        try:
            __salt__['mdl_vault.enable_secret_backend'](backend_type,
                                                    description=description,
                                                    mount_point=mount_point)
            ret['result'] = True
            ret['changes']['new'] = __salt__[
                'mdl_vault.list_secret_backends']()
        except __utils__['mdl_vault.vault_error']() as e:
            ret['result'] = False
            log.exception(e)
        if connection_config:
            if not connection_config_path:
                connection_config_path = '{mount}/config/connection'.format(
                    mount=mount_point)
            try:
                __salt__['mdl_vault.write'](connection_config_path,
                                        **connection_config)
            except __utils__['mdl_vault.vault_error']() as e:
                ret['comment'] += ('The backend was enabled but the connection '
                                  'could not be configured\n')
                log.exception(e)
                raise salt.exceptions.CommandExecutionError(str(e))
        if ttl_max or ttl_default:
            ttl_config_path = 'sys/mounts/{mount}/tune'.format(
                mount=mount_point)
            if ttl_default > ttl_max:
                raise salt.exceptions.SaltInvocationError(
                    'The specified default ttl is longer than the maximum')
            if ttl_max and not ttl_default:
                ttl_default = ttl_max
            if ttl_default and not ttl_max:
                ttl_max = ttl_default
            try:
                log.debug('Tuning the mount ttl to be: Max={ttl_max}, '
                          'Default={ttl_default}'.format(
                              ttl_max=ttl_max, ttl_default=ttl_default))
                __salt__['mdl_vault.write'](ttl_config_path,
                                        default_lease_ttl=ttl_default,
                                        max_lease_ttl=ttl_max)
            except __utils__['mdl_vault.vault_error']() as e:
                ret['comment'] += ('The backend was enabled but the connection '
                                  'ttl could not be tuned\n'.format(e))
                log.exception(e)
                raise salt.exceptions.CommandExecutionError(str(e))
        if lease_max or lease_default:
            lease_config_path = '{mount}/config/lease'.format(
                mount=mount_point)
            if lease_default > lease_max:
                raise salt.exceptions.SaltInvocationError(
                    'The specified default lease is longer than the maximum')
            if lease_max and not lease_default:
                lease_default = lease_max
            if lease_default and not lease_max:
                lease_max = lease_default
            try:
                log.debug('Tuning the lease config to be: Max={lease_max}, '
                          'Default={lease_default}'.format(
                              lease_max=lease_max, lease_default=lease_default))
                __salt__['mdl_vault.write'](lease_config_path,
                                        ttl=lease_default,
                                        max_ttl=lease_max)
            except __utils__['mdl_vault.vault_error']() as e:
                ret['comment'] += ('The backend was enabled but the lease '
                                  'length could not be configured\n'.format(e))
                log.exception(e)
                raise salt.exceptions.CommandExecutionError(str(e))
        ret['comment'] += ('The {backend} backend has been successfully mounted at '
                          '{mount}.'.format(backend=backend_type,
                                            mount=mount_point or backend_type))
    return ret


def policy_present(name, rules):
    """
    Ensure that the named policy exists and has the defined rules set

    :param name: The name of the policy
    :param rules: The rules to set on the policy
    :returns: The result of the state execution
    :rtype: dict
    """
    current_policy = __salt__['mdl_vault.get_policy'](name)
    ret = {'name': name,
           'comment': '',
           'result': False,
           'changes': {}}
    if current_policy == rules:
        ret['result'] = True
        ret['comment'] = ('The {policy_name} policy already exists with the '
                          'given rules.'.format(policy_name=name))
    elif __opts__['test']:
        ret['result'] = None
        if current_policy:
            ret['changes']['old'] = current_policy
            ret['changes']['new'] = rules
        ret['comment'] = ('The {policy_name} policy will be {suffix}.'.format(
            policy_name=name,
            suffix='updated' if current_policy else 'created'))
    else:
        try:
            __salt__['mdl_vault.set_policy'](name, rules)
            ret['result'] = True
            ret['comment'] = ('The {policy_name} policy was successfully '
                              'created/updated.'.format(policy_name=name))
            ret['changes']['old'] = current_policy
            ret['changes']['new'] = rules
        except __utils__['mdl_vault.vault_error']() as e:
            log.exception(e)
            ret['comment'] = ('The {policy_name} policy failed to be '
                              'created/updated'.format(policy_name=name))
    return ret


def policy_absent(name):
    """
    Ensure that the named policy is not present

    :param name: The name of the policy to be deleted
    :returns: The result of the state execution
    :rtype: dict
    """
    current_policy = __salt__['mdl_vault.get_policy'](name)
    ret = {'name': name,
           'comment': '',
           'result': False,
           'changes': {}}
    if not current_policy:
        ret['result'] = True
        ret['comment'] = ('The {policy_name} policy is not present.'.format(
            policy_name=name))
    elif __opts__['test']:
        ret['result'] = None
        if current_policy:
            ret['changes']['old'] = current_policy
            ret['changes']['new'] = {}
        ret['comment'] = ('The {policy_name} policy {suffix}.'.format(
            policy_name=name,
            suffix='will be deleted' if current_policy else 'is not present'))
    else:
        try:
            __salt__['mdl_vault.delete_policy'](name)
            ret['result'] = True
            ret['comment'] = ('The {policy_name} policy was successfully '
                              'deleted.')
            ret['changes']['old'] = current_policy
            ret['changes']['new'] = {}
        except __utils__['mdl_vault.vault_error']() as e:
            log.exception(e)
            ret['comment'] = ('The {policy_name} policy failed to be '
                              'created/updated'.format(policy_name=name))
    return ret


def role_present(name, mount_point, options, override=False):
    """
    Ensure that the named role exists. If it does not already exist then it
    will be created with the specified options.

    :param name: The name of the role
    :param mount_point: The mount point of the target backend
    :param options: A dictionary of the configuration options for the role
    :param override: Write the role definition even if there is already one
                     present. Useful if the existing role doesn't match the
                     desired state.
    :returns: Result of executing the state
    :rtype: dict
    """
    current_role = __salt__['mdl_vault.read']('{mount}/roles/{name}'.format(
        mount=mount_point, name=name))
    ret = {'name': name,
           'comment': '',
           'result': False,
           'changes': {}}
    if current_role and not override:
        ret['result'] = True
        ret['comment'] = ('The {role} role already exists with the '
                          'given rules.'.format(role=name))
    elif __opts__['test']:
        ret['result'] = None
        if current_role:
            ret['changes']['old'] = current_role
            ret['changes']['new'] = None
        ret['comment'] = ('The {role} role {suffix}.'.format(
            role=name,
            suffix='already exists' if current_role else 'will be created'))
    else:
        try:
            response = __salt__['mdl_vault.write']('{mount}/roles/{role}'.format(
                mount=mount_point, role=name), **options)
            ret['result'] = True
            ret['comment'] = ('The {role} role was successfully '
                              'created.'.format(role=name))
            ret['changes']['old'] = current_role
            ret['changes']['new'] = response
        except __utils__['mdl_vault.vault_error']() as e:
            log.exception(e)
            ret['comment'] = ('The {role} role failed to be '
                              'created'.format(role=name))
    return ret


def role_absent(name, mount_point):
    """
    Ensure that the named role does not exist.

    :param name: The name of the role to be deleted if present
    :param mount_point: The mount point of the target backend
    :returns: The result of the stae execution
    :rtype: dict
    """
    current_role = __salt__['mdl_vault.read']('{mount}/roles/{name}'.format(
        mount=mount_point, name=name))
    ret = {'name': name,
           'comment': '',
           'result': False,
           'changes': {}}
    if current_role:
        ret['changes']['old'] = current_role
        ret['changes']['new'] = None
    else:
        ret['changes'] = None
        ret['result'] = True
    if __opts__['test']:
        ret['result'] = None
        return ret
    try:
        __salt__['mdl_vault.delete']('{mount}/roles/{name}'.format(
            mount=mount_point, name=name))
        ret['result'] = True
    except __utils__['mdl_vault.vault_error']() as e:
        log.exception(e)
        raise salt.exceptions.SaltInvocationError(e)
    return ret


def _dict_diff(old_dict, new_dict):
    return RecursiveDictDiffer(old_dict, new_dict, ignore_missing_keys=False).diffs


def _resolve_pillar_keys(dictionary):
    ret = copy.deepcopy(dictionary)
    pillar_suffix = '_pillar'
    pillar_get = __salt__['pillar.get']
    for key, value in dictionary.items():
        if key.endswith(pillar_suffix):
            pure_key = key[:-len(pillar_suffix)]
            del ret[key]
            if isinstance(value, (tuple, list)):
                # Resolve for each item in the list
                pillar_values = []
                for list_value in value:
                    pillar_values.append(pillar_get(list_value))
                ret[pure_key] = pillar_values
            else:
                ret[pure_key] = pillar_get(value)
    return ret
