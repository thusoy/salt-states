leiningen:
    cmd.run:
        - name: wget
                -N
                -O /usr/local/bin/lein
                https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein &&
                chmod 755 /usr/local/bin/lein
        - unless: test -x /usr/local/bin/lein
