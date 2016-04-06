# Extracted the purge-old-kernels script from the bikeshed package

purge-old-kernels:
    file.managed:
        - name: /usr/local/bin/purge-old-kernels
        - source: salt://purge-old-kernels/purge-old-kernels.sh
        - mode: 755
