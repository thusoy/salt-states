{% set swap = pillar.get('swap', {}) %}
{% set swap_size = swap.get('size_mb', '2048') %}
{% set swap_location = swap.get('location', '/.swapfile') %}


swapfile:
    cmd.run:
        - name: (umask 077; dd if=/dev/zero of={{ swap_location }} bs=1M count={{ swap_size }}) &&
                mkswap {{ swap_location }}
        - unless: file {{ swap_location }} 2>&1 | grep -q "Linux/i386 swap" &&
                  [ $(wc -c {{ swap_location }} | cut -d' ' -f1) -eq {{ swap_size|int * 2**20 }} ]


swap:
    mount.swap:
        - name: {{ swap_location }}
        - require:
            - cmd: swapfile

    cmd.watch:
        - name: swapon -a
        - watch:
            - mount: swap
        - order: 1
