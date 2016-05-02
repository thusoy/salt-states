samba
=====

Hosts a samba server for user directories. Customize through the user pillar with a section `samba` for each user specifying the name of the directory to share and a password:

    users:
        joe:
            samba:
                directory: joesfiles
                password: joespassword

This pillar will ensure that the directory `/home/joe/joesfiles` exists and is available over samba (CIFS).
