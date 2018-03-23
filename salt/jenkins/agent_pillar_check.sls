#!py

def run():
    """
    Sanity check the jenkins agent pillar to ensure that all required fields
    are present.
    """
    master_pubkey = __salt__['pillar.get']('jenkins:master_ssh_pubkey')
    assert master_pubkey, 'jenkins:master_ssh_pubkey must be defined in pillar'
    return {}
