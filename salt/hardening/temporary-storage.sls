# Make sure /tmp, /var/tmp and /dev/shm are all nodev, nosuid and noexec
# Ref. NSA RHEL guide section 2.2.1.3

# We cannot re-partition a running system without risking data loss, thus if you
# want strict separation between partitions this has to be configured manually
# before getting to the provisioning stage.

# There's two concerns adressed by partitioning, one is that it enables
# world-writable locations like /tmp, /var/tmp and /dev/shm to run with more
# restrictive mount options like noexec,nosuid. This is a security benefit.

# The other concern is availability, if world-writeable directories are on the
# same partition as the rest of the OS, any local user can fill the partition
# and cause the system to become unstable or prevent normal operation of other
# programs on the system. This extends also to directories which hold variable
# data which can be influenced by an attacker, like /var/log, which also
# shouldn't be able to bring the system down if filled up. Spamming a web server
# or ssh daemon can cause it to log enough to fill this up.

# We can remount /tmp, /var/tmp and /dev/shm as tmpfs, since that doesn't
# require any repartitioning, but does limit the size of these. If a larger /tmp
# is needed and there's not enough memory to keep it as tmpfs, the easiest step
# is to turn this off by setting os:tmp_in_memory to False. This will also turn
# off the noexec restrictions on /tmp and /var/tmp. To keep /var/tmp on the root
# filesystem and only make /tmp tmpfs, set os:bind_mount_var_tmp to False.

{% set tmp_size = salt['pillar.get']('os:tmp_size', '1G') %}
{% set shm_size = salt['pillar.get']('os:shm_size', '30%') %}
{% set temp_directories_in_memory = salt['pillar.get']('os:temp_directories_in_memory', True) %}
{% set bind_mount_var_tmp = salt['pillar.get']('os:bind_mount_var_tmp', True) %}

hardening-/tmp:
{% if temp_directories_in_memory %}
    mount.mounted:
        - name: /tmp
        - device: tmpfs
        - fstype: tmpfs
        - opts:
            - defaults
            - nodev
            - noexec
            - nosuid
            - "size={{ tmp_size }}"
{% else %}
    # Remove any previous tmpfs config that might have been added
    mount.unmounted:
        - name: /tmp
        - device: tmpfs
        - persist: True
{% endif %}


hardening-/var/tmp:
{% if temp_directories_in_memory and bind_mount_var_tmp %}
    mount.mounted:
        - name: /var/tmp
        - device: /tmp
        - fstype: none
        - opts:
            - bind
{% else %}
    # TODO: Make sure this isn't unmounted if on a separate partition
    # On 2018.3.0 and newer this can use mount.read_mount_cache to check the current mount target and only unmount if device is /tmp
    mount.unmounted:
        - name: /var/tmp
        - persist: True
{% endif %}


hardening-/dev/shm:
    mount.mounted:
        - name: /dev/shm
        - device: tmpfs
        - fstype: tmpfs
        - opts:
            - defaults
            - nodev
            - noexec
            - nosuid
            - mode=1777
            - "size={{ shm_size }}"
