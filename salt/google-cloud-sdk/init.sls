google-cloud-sdk:
    pkgrepo.managed:
        - name: deb http://packages.cloud.google.com/apt cloud-sdk-{{ grains.oscodename }} main
        - key_url: salt://google-cloud-sdk/apt-key.gpg

    pkg.installed:
        - require:
            - pkgrepo: google-cloud-sdk

