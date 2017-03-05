vim:
    pkg.installed: []

    file.managed:
        - name: /etc/vim/vimrc.local
        - source: salt://vim/vimrc
