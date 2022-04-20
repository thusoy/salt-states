laim:
    config:
        slack-channel-id: '#servers'
        slack-token: my-slack-api-token
        honeycomb-dataset: my-dataset
        honeycomb-key: my-honeycomb-key

hart:
    providers:
        do:
            token: foo

        vultr:
            token: bar

        ec2:
            aws_access_key_id: foo
            aws_secret_access_key: bar

        gce:
            project: project
            user_id: user_id
            key: fookey

    config: |
        [hart]
        role_naming_scheme = "{unique_id}.{zone}.{provider}.{role}.example.com"


rabbitmq:
    admin_password: admin
    monitoring_password: monitoring
    # Uncomment this to expose management panel without tls
    # management_expose_plaintext: True

redis:
    maxmemory: '50%'
    # password: foobar
    password_pillar: other-pillar:password

other-pillar:
    password: otherpass

boto:
    access_key_id: foobar
    secret_access_key: secretbar
    # secret_access_key_pillar: test_pillar:value


test_pillar:
    value: other pillar value


vault:
    server_config:
        api_addr: https://10.10.10.23
        storage:
            file:
                path: /tmp/vault
    tls_cert: |
        -----BEGIN CERTIFICATE-----
        MIIByTCCAW+gAwIBAgIUP9dSMiMTNhTGWlp/Xkk3FwubO14wCgYIKoZIzj0EAwIw
        UTEZMBcGA1UEBwwQVGVzdCBFbnZpcm9ubWVudDERMA8GA1UECgwITWVnYWNvb2wx
        ETAPBgNVBAsMCEludGVybmFsMQ4wDAYDVQQDDAV2YXVsdDAeFw0yMDAyMTMxODI3
        MDBaFw0zMDAyMTAxODI3MDBaMFExGTAXBgNVBAcMEFRlc3QgRW52aXJvbm1lbnQx
        ETAPBgNVBAoMCE1lZ2Fjb29sMREwDwYDVQQLDAhJbnRlcm5hbDEOMAwGA1UEAwwF
        dmF1bHQwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAARNDBJFaCx2MAYL9iyOO045
        GtnPKutvieDjja00uQC3nC1Y7r28jpuKYjbxBVJLX4yhjWTEiaAmTLBnKwmiD2VZ
        oyUwIzAhBgNVHREEGjAYhwR/AAABgglsb2NhbGhvc3SCBXZhdWx0MAoGCCqGSM49
        BAMCA0gAMEUCIDONzX81HWq5wiW7oN129anj6g5Pr6QFoEpLuGlm0RNNAiEA1y17
        0lOWRrcUsIQHc+niF8cZ2yiFhBML+C6o787BphU=
        -----END CERTIFICATE-----
    tls_key: |
        -----BEGIN EC PARAMETERS-----
        BggqhkjOPQMBBw==
        -----END EC PARAMETERS-----
        -----BEGIN EC PRIVATE KEY-----
        MHcCAQEEIGtx9TuAD2rXW3jpXFa90qxxgdI/NS09FvPbOnTpduRNoAoGCCqGSM49
        AwEHoUQDQgAETQwSRWgsdjAGC/YsjjtOORrZzyrrb4ng442tNLkAt5wtWO69vI6b
        imI28QVSS1+MoY1kxImgJkywZysJog9lWQ==
        -----END EC PRIVATE KEY-----
    # dev: True
    policies:
        read-only:
            path:
                '*':
                    capabilities: ['read']

    auth_backends:
        - backend_type: github
          description: 'github backend description'
          config:
            organization: some-github-org

        - backend_type: gcp
          description: Google Cloud
          roles:
            - name: my-read-only-role
              config:
                type: iam
                policies: read-only
                bound_service_accounts_pillar:
                    - terraform:vault_service_account

    secrets_engines:
        - type: kv
          description: kv version 2 engine
          mount_point: secrets
          options:
            version: 2

    audit:
        - backend_type: syslog

terraform:
    vault_service_account: test-app@test-project.iam.gserviceaccount.com


sentry_forwarder:
    port: 5010
    sampling_rate: 10
    user_agent_sampling_rates:
        my-ua/1.0: 2


elasticsearch:
    cluster_name: medal-test-cluster
    memory: 1g
    http_publish_host: 10.10.10.23
    seed_hosts:
        - 127.0.0.1
        - 10.10.10.24


honeytail:
    write_key: foobar
    log_file: /var/log/nginx/access.log
    parser_name: keyval
    dataset: vagrant
    debug: True
    request_shape: path
    request_patterns:
        - /apps/:app_identifier
    drop_fields:
        - path_path
    add_grains:
        - cpu_model
        - kernelrelease
        - mem_total


docker-ce:
    iptables: False


docker:
    hosts:
        - tcp://0.0.0.0:2376


ghost-cli:
    # this is the hash for 'vagrant'
    user_password: $6$8jtQaRqHihuwm4Iu$cKidi.pA/oms3hFHpZ73GF/lVkWQcsIMhHMCpBfPM2iaxJb4.JQeWMSVBnfJY4orVbcC.nGq7HJcpkiRPnsvn.


rsyslog:
    configs:
        12-nginx: |
            :msg, startswith, "nginx" -/var/log/nginx2.log
            & stop
            :msg, regex, "^ *\[ *[0-9]*\.[0-9]*\] nginx" -/var/log/nginx-reg.log
            & stop


os:
    temp_directories_in_memory: False


git:
    install_from_source: True
    version: 2.12.0 sha256=1821766479062d052cc1897d0ded95212e81e5c7f1039786bc4aec2225a32027


openssh_client:
    known_hosts:
        "example.com":
            - ssh-rsa AAAAB3Nz<..>UoxVdTB
        "[customport.example.com]:3271":
            - ssh-ed25519 AAAAC<..>8WM1
            - ssh-rsa AAAAB3Nz<..>eLeW3TZ


openssh_server:
    allow_groups: []
    host_ed25519_key: |
        -----BEGIN OPENSSH PRIVATE KEY-----
        b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
        QyNTUxOQAAACAUCzHIKGXG4GnpF2tCcXwSq013gROeoL3YKYC1FpDBgQAAAJgEhRIKBIUS
        CgAAAAtzc2gtZWQyNTUxOQAAACAUCzHIKGXG4GnpF2tCcXwSq013gROeoL3YKYC1FpDBgQ
        AAAEBRqtBkjjNnmauCvO/WYWV6lALsraCmageYM+0CB9LCjxQLMcgoZcbgaekXa0JxfBKr
        TXeBE56gvdgpgLUWkMGBAAAAFXRhcmplaUAzMTMudGh1c295LmNvbQ==
        -----END OPENSSH PRIVATE KEY-----


cachish:
    items:
        /github-ips:
            module: JsonHttp
            disable_auth: True
            parameters:
                url: https://api.github.com/meta
                field: git


timezone: UTC


cron:
    mailto: test@example.com


tls-terminator:
    error_pages:
        {% raw %}
        429: |
            <!doctype html>
            <title>That's enough</title>
            <p>Too much traffic from you to {{ site }}, give the poor server a rest.</p>
        {% endraw %}
        504:
            content_type: application/json
            content: |
                {
                    "error": {
                        "status": 502,
                        "message": "Timed out"
                    }
                }
    redirect.com:
        redirect: https://example.com

    example.com:
        backends:
            /:
                upstreams:
                    - http://127.0.0.1:5000 weight=3
                    - http://127.0.0.1:5001
                upstream_keepalive: 16
                upstream_least_conn: True
                add_headers:
                    X-Frame-Options: sameorigin
            /other: http://127.0.0.1:5002
            /foo:
                redirect: 'https://foo.com'
        extra_locations:
            /.well-known/assetlinks.json: |
                add_header content-type application/json;
                return 200 '[{ "namespace": "android_app",
                   "package_name": "org.digitalassetlinks.example",
                   "sha256_cert_fingerprints":
                     ["14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:"
                      "A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5"]}]';
        rate_limit:
            zones:
                default:
                    size: 3m
                    rate: 5r/m
                sensitive:
                    size: 1m
                    rate: 2r/m
            backends:
                /:
                    zone: default
                    burst: 3
                /login:
                    zone: sensitive
                    burst: 2


hardening:
    module_blacklist:
        - i2c_core
        - cdrom


dotfiles:
    thing: |
        hello
        is there anybody out there?


users:
    vagrant:
        install:
            - pyenv
    tempuser:
        optional_groups:
            - phpworker
        dotfiles:
            .bashrc:
                contents_pillar: dotfiles:thing
                mode: 754


nginx:
    security_txt: https://example.com/security.txt
    ssl_session_tickets:
        - xWBv1uzOZNFM2ZAmIQKTziVkPELcDjTIM5C5Joxeo7N4wb3LCsExZV6QKHxoZwpX28BZzeujG0QoqcVa+pY/fCxnowAqADeErOC0pEk2Zq0=
        - WRbGxc7dgZtPbuiYF16LOBylxD3ApXFbI8jesZwYtXNLVO5Z9gFnI+bU7DA93gvS
    allow_sources_v4:
        - 127.0.0.1
        - 127.0.0.3
    allow_sources_v6:
        - fe80::abcd
    proxy_read_timeout: 30
    log_formats:
        # Log with logfmt to make it easier to do ad-hoc analysis with lcut and similar tools,
        # make it easy to forward parameters to honeycomb with a logfmt parser without having to
        # change the format in multiple locations, and make it easy to sample incoming logs on
        # papertrail (with a filter like `request_id=[0-8].*status=2` f. ex)
        main: 'time=$time_iso8601 client=$remote_addr host=$http_host
               method=$request_method path="$request_uri" status=$status bytes=$body_bytes_sent
               total_time=$request_time ua="$http_user_agent"'
    default_key: |
        -----BEGIN RSA PRIVATE KEY-----
        MIIEpQIBAAKCAQEA6ss5SR5Ut0bBdrEol//1pjPWTS1o7Q5q3nmPnZwQ1ZGz387u
        bJTfyVPwc/RPvMtSlRwBJGk/q/kdmbm8CxD7fPCspMVOp9zP/jdQvBIKRb224B0m
        lta7EcJeCeWj6f/RO3rEP8QZLh5GL8FYRkrpBalD1qjWqRmerz6oHQb23oqmAwvZ
        NHEcfpkixg9g1+PFGVNHcuPhbrI9Ot6LW+SXd8DdGqEE4XQYDBJ2E7sPFsHiir32
        8xH7DFSuzw/9gkYpBF8E+B4Su+r6lPqSVeGGJ4I9M87kt+TA/uey1WLXcfwsyjwU
        RyhJ5SYkKW1x6Ctqd9kztWfeQzm0BhbIoNKGjwIDAQABAoIBAQCl9DJvXgLe8CH6
        NMnOddo5OVZ1gm0xcQlUanN6IT881RlgTbD0Cl4KvUutibd6Z/Pc9MhR5hpdAV1M
        tJ0W7U/0RWChrdwkhcx1kL99zvp3xNonmjMWVnwu10UElc2/rVNESUfBEmgB0uAl
        DPHJ7VS67aLHbNsc9sDUeOL2cV+4dsi97JhN302nk/gMf6nKYXEoHhSxwuryIW52
        H43DDwD9xd+8dYpAlbiQunoQe63BYRN2qkalbfkqnmxKdivpE32ZJzhBM/KOiS88
        TJojH0X1qF9Q9Hhw0E565+9Pay7gH30LvOMlOu+KxtfcGupDwVliGiUe6E18N9gA
        cZBB0mIhAoGBAPb/2buXJOtVEvSy4hjNO0j2gPCUUYbXldsAjGPyTGsOuk2Ho6Cy
        7DM/vBwsXXJi2KaDzndMqg3B6Tjl2JFg/lzCekAbwZJ9yNTKAyJmqMy/Mkyquvi/
        bKxJpy2zvCs1ovMrvU+S1Snek7RUMBJilM5RmGBToA7vkS7c2a8gmlAZAoGBAPNZ
        g0btn1X2yuvJf64uyKbhcm1rJY3+BhvHLlqNNtcFY3bsi7TmzsJ3A1DyC1qZgC53
        ZuL2owCTNNp6WgncgvjlrGP9SYvYg1D9tkm/ZfKJHa0Jwj4ywkA3nAycx4sAxUBS
        UV5aNWkCuTJIxeuumOnr++zae69svcvMtG+HvkDnAoGBAMvZjJFNxKKUq/hYSlG9
        z9f/2Zq0TjTDaGI+qZ8zMe6JUSj7cQgHovkI+O8njlgBTFzhG11KYG7KQvk6eOpC
        6qsTtmGChteoCD/WGZAiud2BTroHjhgNpFrszpThacMfmUSoLK2nuVW85JpHgQUr
        ZzSAEwos+kRZY7ERhHcMqU7BAoGABC5XiRJwGGQDHIX7wZxgKi3Zb3PV01i39iY3
        76pZdNxM1zA9PkBw8Ppmfi+KbmYQw7udcuzV5B6jW9WaUm0NewVHLvidGOABcZTK
        Wv4E3GPqtJxkT/lDSSMrdTQEYakDupUvfLWEEWfQksKZU/FOA0bgrzMZyOvPXv8H
        Ypssc6UCgYEAwEERhC7x7HyYZBGcaymsA7MJHW45RkfQAFlIZBDcobOuw16G3ay6
        2+tx3gJMLWxKaZUmnbRbnxJ6GR0FJoZ3iK4EJsKn+JKLlWN+M8yUHad24UbboA4K
        pZW9KisJNsoqFqxRl3feZ5+rqDq17ILiQXZoO8CFrl7M1qmEf8wQyz4=
        -----END RSA PRIVATE KEY-----

    default_cert: |
        -----BEGIN CERTIFICATE-----
        MIICtDCCAZwCCQCSSMI5piC8NDANBgkqhkiG9w0BAQsFADAcMRowGAYDVQQDDBFw
        b2ZmLnRodXNveS5sb2NhbDAeFw0xNjExMjAwNzAzMzVaFw0yNjExMTgwNzAzMzVa
        MBwxGjAYBgNVBAMMEXBvZmYudGh1c295LmxvY2FsMIIBIjANBgkqhkiG9w0BAQEF
        AAOCAQ8AMIIBCgKCAQEA6ss5SR5Ut0bBdrEol//1pjPWTS1o7Q5q3nmPnZwQ1ZGz
        387ubJTfyVPwc/RPvMtSlRwBJGk/q/kdmbm8CxD7fPCspMVOp9zP/jdQvBIKRb22
        4B0mlta7EcJeCeWj6f/RO3rEP8QZLh5GL8FYRkrpBalD1qjWqRmerz6oHQb23oqm
        AwvZNHEcfpkixg9g1+PFGVNHcuPhbrI9Ot6LW+SXd8DdGqEE4XQYDBJ2E7sPFsHi
        ir328xH7DFSuzw/9gkYpBF8E+B4Su+r6lPqSVeGGJ4I9M87kt+TA/uey1WLXcfws
        yjwURyhJ5SYkKW1x6Ctqd9kztWfeQzm0BhbIoNKGjwIDAQABMA0GCSqGSIb3DQEB
        CwUAA4IBAQAhwxFlUPs375pHFPIUnkTnepIBekeGWfa2e5ysP72GIov5WxwHB2Jd
        7Ot8H9I9vxDN/M4+e2jPclSgUQ4MqWF7c5DialmVT2ewEd4B+hFzGBnziwV788EE
        C4AEsIW7ziYiaYcs+3AsIOJuEDD/yjCtfFqPcAuRmdOcbRv4QTmpzL7XyD1NuRoM
        es9yj3bueFEjt5D/IG89oAL0MwVeGdpeRJYHPrxGVKcQXHJCeFec6AAec/PuhKSg
        lg7nl2gjOQCwVCqWwnUDEzeG22085x+oMEDIkiO5TRjb/qvD0W/P2ZsLIQ4pWiq5
        uQzxQaXj4QJB0eR3IZ5n6kLLWiLEe/Hu
        -----END CERTIFICATE-----


postgres.host: '10.20.30.40'
postgres:
    version: 9.5
    internal: False
    cert: |
        -----BEGIN CERTIFICATE-----
        MIIBLTCB0wIJAP73Wy8Jn2kQMAoGCCqGSM49BAMCMCAxHjAcBgNVBAMMFXBvbnl0
        YS5tZWdhY29vbC5sb2NhbDAeFw0xNjA1MTkwMzA2MzJaFw0yNjA1MTcwMzA2MzJa
        MCAxHjAcBgNVBAMMFXBvbnl0YS5tZWdhY29vbC5sb2NhbDBWMBAGByqGSM49AgEG
        BSuBBAAKA0IABOUyNG94k0SI0PUcw9dwx46CplOoZTHVbmTnUQnwaEBe4S+KCIhh
        OOt6nx5KpLzDegasPMsXmdr+RwKX+P1+KjIwCgYIKoZIzj0EAwIDSQAwRgIhAIeS
        31YDFpvNHzStTUeoLiiDu65OHUyBZsFqDTk8s+E1AiEA3mUjdhud7ls94Bf1LyuS
        VjDwjEM/idlM02mW0/w6THM=
        -----END CERTIFICATE-----

    key: |
        -----BEGIN EC PARAMETERS-----
        BgUrgQQACg==
        -----END EC PARAMETERS-----
        -----BEGIN EC PRIVATE KEY-----
        MHQCAQEEILHlaNEtWFP0PZD9NVCTTqfyWBQEqB6jGzF6HpitO+EdoAcGBSuBBAAK
        oUQDQgAE5TI0b3iTRIjQ9RzD13DHjoKmU6hlMdVuZOdRCfBoQF7hL4oIiGE463qf
        HkqkvMN6Bqw8yxeZ2v5HApf4/X4qMg==
        -----END EC PRIVATE KEY-----


# Don't actually apply iptables to prevent locking ourselves out
iptables:
    apply: False


memcached:
    memory: 128
    port: 11212


sasl2:
    service: memcached
    service_user: memcache
    username: vagrant
    password: vagrant
