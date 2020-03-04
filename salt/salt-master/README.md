# salt-master

Assuming the salt-master is configured as a masterless minion, use this state
to configure it. The configuration should be given in pillar as
`salt_master:master_config` and `salt_master:master_minion_config`, which can be
either yaml or a string. Use a string if you want to preserve comments.
