newrelic-sysmond-absent:
    pkgrepo.absent:
        - name: deb https://apt.newrelic.com/debian newrelic non-free

    pkg.purged:
        - name: newrelic-sysmond
