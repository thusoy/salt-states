import copy

def resolve_leaf_values(dictionary):
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
        elif isinstance(value, dict):
            ret[key] = resolve_leaf_values(value)
    return ret
