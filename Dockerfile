FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update --allow-releaseinfo-change && \
   apt-get install -y gnupg2 ca-certificates \
   && rm -rf /var/lib/apt/lists/*

COPY salt-release-key.asc /tmp/salt-release-key.asc
RUN cat /tmp/salt-release-key.asc \
    | gpg --dearmor \
    | tee /usr/share/keyrings/salt-archive-keyring-2023.gpg >/dev/null && \
    echo 'deb [signed-by=/usr/share/keyrings/salt-archive-keyring-2023.gpg] https://packages.broadcom.com/artifactory/saltproject-deb/ stable main' \
    | tee /etc/apt/sources.list.d/saltstack.list && \
    printf 'Package: salt-*\nPin: version 3006.*\nPin-Priority: 1001\n' \
    | tee /etc/apt/preferences.d/salt-pin-1002

RUN apt-get update --allow-releaseinfo-change && \
    apt-get install -y salt-minion && \
    rm -rf /var/lib/apt/lists/*

# Remove noisy and unused compat module (same as in Vagrant)
RUN rm -f /opt/saltstack/salt/lib/python3.*/site-packages/salt/utils/psutil_compat.py \
          /opt/saltstack/salt/lib/python3.*/site-packages/salt/utils/__pycache__/psutil_compat.cpython-*.pyc

COPY vagrant-minion /etc/salt/minion
COPY salt /srv/salt
COPY pillar /srv/pillar

# Salt states can't modify kernel settings when run from docker unless it's run with
# elevated privileges, to avoid having to do that we mock out the sysctl binary
COPY tools/sysctl-mock.sh /usr/local/bin/sysctl
RUN chmod 755 /usr/local/bin/sysctl

# Sync modules and run iptables to make the firewall state work
RUN salt-call saltutil.sync_all && salt-call state.sls iptables

WORKDIR /srv

ENTRYPOINT ["salt-call", "state.sls"]
