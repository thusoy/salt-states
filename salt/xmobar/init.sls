xmobar-deps:
    pkg.installed:
        - name: cabal


xmobar:
    cmd.run:
        - name: cabal install xmobar --global
        - unless: which xmobar
        - require:
            - pkg: xmobar-deps
