'''
Extensions to work with pillar data.
'''

import copy


def resolve_leaf_values(dictionary):
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
            ret[pure_key] = _resolve_value(value, pillar_get)
        elif key.endswith(grain_suffix):
            pure_key = key[:-len(grain_suffix)]
            del ret[key]
            ret[pure_key] = _resolve_value(value, grain_get)

        elif isinstance(value, dict):
            ret[key] = resolve_leaf_values(value)
        elif isinstance(value, (tuple, list)):
            pillar_values = []
            for list_value in value:
                if isinstance(list_value, dict):
                    pillar_values.append(resolve_leaf_values(list_value))
                else:
                    pillar_values.append(list_value)
            ret[key] = pillar_values
    return ret


def _resolve_value(value, getter):
    if isinstance(value, (tuple, list)):
        # Resolve for each item in the list
        pillar_values = []
        for list_value in value:
            pillar_values.append(getter(list_value))
        return pillar_values
    else:
        return getter(value)
