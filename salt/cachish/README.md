cachish
=======

Installs and configures [cachish](https://github.com/thusoy/cachish).

Pillar example:

```yaml
cachish:
    items:
        /myservice/database-url:
            module: Heroku
            parameters:
                api_token: mytoken
                app: myherokuapp
                config_key: DATABASE_URL

    auth:
        myservicetoken: /myservice/*
```
