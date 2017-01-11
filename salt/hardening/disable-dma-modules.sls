# Try to prevent DMA-based attacks by disabling DMA kernel modules like firewire and pcmcia

{% set dma_kernel_modules = [
    'firewire_core',
    'pcmcia_core',
] %}

{% set custom_module_blacklist = salt['pillar.get']('hardening:module_blacklist', []) %}
{% set modules = dma_kernel_modules + custom_module_blacklist %}


hardening-dma-modules-blacklist:

    # Prevent the modules from loading after reboot and prevent
    # accidental load through dependencies
    file.managed:
        - name: /etc/modprobe.d/blacklist.conf
        - source: salt://hardening/blacklist.conf
        - template: jinja
        - context:
            modules:
                {% for module in modules -%}
                - {{ module }}
                {% endfor %}



hardening-disable-dma-modules-helper-script:
    file.managed:
        - name: /usr/local/bin/print-dependent-modules
        - source: salt://hardening/print_dependent_modules.py
        - mode: 755


{% for kernel_module in modules %}
hardening-dma-disable-{{ kernel_module }}:

    # Unload from currently running kernel
    # First unload all modules dependent on it, then unload the module itself
    cmd.run:
        - name: /usr/local/bin/print-dependent-modules {{ kernel_module }}
                | xargs --no-run-if-empty modprobe --remove
        - onlyif: lsmod | grep ^{{ kernel_module }}
        - require:
            - file: hardening-disable-dma-modules-helper-script

{% endfor %}
