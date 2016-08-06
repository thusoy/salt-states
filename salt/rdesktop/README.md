rdesktop
========

Handy for connecting to Windows hosts.

To connect to a host and port not exposed publicly, you can connect over a SSH tunnel via a jump-host:

    $  ssh <jump-host> -N -L 43389:<ip-of-target-host>:3389

And then connect to the now local port:

    $ rdesktop localhost:43389 -g 90% -u <username>
