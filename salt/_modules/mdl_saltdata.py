'''
Extensions to work with pillar data.
'''

import copy


def resolve_leaf_values(dictionary, collapse_lists=False):
    '''
    Replace all leaf values with keys that end in `_pillar` or _grain with the value from pillar/grains
    with the key given in the value.

    For example:

    example:
        key_pillar: other:thing

    with the pillar:

    other:
        thing: pillar value

    becomes

    example:
        key: pillar value

    Use the `collapse_lists` kwarg if you want items that resolve to lists to be stringified as a csv.
    '''
    ret = copy.deepcopy(dictionary)
    grain_suffix = '_grain'
    pillar_suffix = '_pillar'
    pillar_get = __salt__['pillar.get']
    grain_get = __salt__['grains.get']
    for key, value in dictionary.items():
        if key.endswith(pillar_suffix):
            pure_key = key[:-len(pillar_suffix)]
            del ret[key]
            ret[pure_key] = _resolve_value(value, pillar_get, collapse_lists)
        elif key.endswith(grain_suffix):
            pure_key = key[:-len(grain_suffix)]
            del ret[key]
            ret[pure_key] = _resolve_value(value, grain_get, collapse_lists)

        elif isinstance(value, dict):
            ret[key] = resolve_leaf_values(value, collapse_lists)
        elif isinstance(value, (tuple, list)):
            pillar_values = []
            for list_value in value:
                if isinstance(list_value, dict):
                    pillar_values.append(resolve_leaf_values(list_value, collapse_lists))
                else:
                    pillar_values.append(list_value)
            ret[key] = pillar_values
    return ret


def _resolve_value(value, getter, collapse_lists):
    if isinstance(value, (tuple, list)):
        # Resolve for each item in the list
        pillar_values = []
        for list_value in value:
            pillar_values.append(_maybe_collapse_list(getter(list_value), collapse_lists))
        return pillar_values
    else:
        return _maybe_collapse_list(getter(value), collapse_lists)


def _maybe_collapse_list(value, collapse_lists):
    if not collapse_lists:
        return value
    if not isinstance(value, (tuple, list)):
        return value
    return ','.join(value)
