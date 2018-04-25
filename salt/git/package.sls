git:
    pkg.installed:
        # Adding the unless here prevents the state from failing on macOS
        # where git is already installed but homebrew isn't
        - unless: which git
