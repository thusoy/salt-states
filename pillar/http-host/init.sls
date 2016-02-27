http-host:
    client-trusted-roots: |
        # tls-terminators.internals.megacool.co
        -----BEGIN CERTIFICATE-----
        MIICdzCCAhygAwIBAgIBATAKBggqhkjOPQQDBDBrMREwDwYDVQQKDAhNZWdhY29v
        bDEmMCQGA1UECwwdUHVibGljLWZhY2luZyBUTFMgdGVybWluYXRvcnMxLjAsBgNV
        BAMMJXRscy10ZXJtaW5hdG9ycy5pbnRlcm5hbHMubWVnYWNvb2wuY28wHhcNMTYw
        MjI2MjAxOTExWhcNMzYwMjIxMjAxOTExWjBrMREwDwYDVQQKDAhNZWdhY29vbDEm
        MCQGA1UECwwdUHVibGljLWZhY2luZyBUTFMgdGVybWluYXRvcnMxLjAsBgNVBAMM
        JXRscy10ZXJtaW5hdG9ycy5pbnRlcm5hbHMubWVnYWNvb2wuY28wVjAQBgcqhkjO
        PQIBBgUrgQQACgNCAAQlCFG/pww7nQIjowoubibfoKM91g5x6V/MpHfuBgvZklad
        uTsAOXM1vXjO8Z3uYYGWBGwGMfudlKl5UGbaSLiSo4GzMIGwMA4GA1UdDwEB/wQE
        AwIBBjASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBRQekb9fe2ZeptlU0BZ
        JT+J85J0PDAfBgNVHSMEGDAWgBRQekb9fe2ZeptlU0BZJT+J85J0PDBKBgNVHR8E
        QzBBMD+gOaA3hjVodHRwczovL3Rscy10ZXJtaW5hdG9ycy5pbnRlcm5hbHMubWVn
        YWNvb2wuY28vY3JsLnBlbYECAE0wCgYIKoZIzj0EAwQDSQAwRgIhAN65Ehm1eZor
        FilANVn3/TMm0ecDlgSuW17naY398WhcAiEA7qC77VAYlk3dFQBxmWmmISzO4Ifq
        SiBvDNkkQe+C2w4=
        -----END CERTIFICATE-----
    meowth:
        key: |
            -----BEGIN EC PARAMETERS-----
            BgUrgQQACg==
            -----END EC PARAMETERS-----
            -----BEGIN EC PRIVATE KEY-----
            MHQCAQEEINsZ2HIVfhSy48iS+etQJpNFW/Q7ef8n4v9efOqQbBY2oAcGBSuBBAAK
            oUQDQgAE8Pdnp0W1IPShDIkKrfCcT+4MUi3XP7tIyF5cAOnvp6wR2SQTqXVPokcD
            gwdg1Q/KZqzMyBEI2C5DDUnWP37a5w==
            -----END EC PRIVATE KEY-----
        cert: |
            -----BEGIN CERTIFICATE-----
            MIICdTCCAhugAwIBAgIBAzAKBggqhkjOPQQDBDBoMREwDwYDVQQKDAhNZWdhY29v
            bDEoMCYGA1UECwwfSW50ZXJuYWwgaG9zdHMgZm9yIEhUVFAgc2VydmVyczEpMCcG
            A1UEAwwgaHR0cC1ob3N0cy5pbnRlcm5hbHMubWVnYWNvb2wuY28wHhcNMTYwMjI2
            MjMzMjM0WhcNMTYwODI0MjMzMjM0WjBvMREwDwYDVQQKDAhNZWdhY29vbDEoMCYG
            A1UECwwfSW50ZXJuYWwgaG9zdHMgZm9yIEhUVFAgc2VydmVyczEwMC4GA1UEAwwn
            bWVvd3RoLmh0dHAtaG9zdHMuaW50ZXJuYWxzLm1lZ2Fjb29sLmNvMFYwEAYHKoZI
            zj0CAQYFK4EEAAoDQgAE8Pdnp0W1IPShDIkKrfCcT+4MUi3XP7tIyF5cAOnvp6wR
            2SQTqXVPokcDgwdg1Q/KZqzMyBEI2C5DDUnWP37a56OBsTCBrjAOBgNVHQ8BAf8E
            BAMCBaAwCQYDVR0TBAIwADAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIw
            HQYDVR0OBBYEFB+q1oRWSEH51IE2DhNTSosb9rkxMB8GA1UdIwQYMBaAFJTyllNp
            r/tTgKfbJBSLUHSv5LECMDIGA1UdEQQrMCmCJ21lb3d0aC5odHRwLWhvc3RzLmlu
            dGVybmFscy5tZWdhY29vbC5jbzAKBggqhkjOPQQDBANIADBFAiBaobNhfvGXr63C
            reYRobJ3vCTkVYkST99a1u3C4lI8nQIhAPUibVCSeI5YtY/3aEecivpFgEdgRzlM
            1YpXGtjXWpuj
            -----END CERTIFICATE-----


tls-terminator:
    megacool.co:
        backend: https://internal.megacool.co:8443
        proxy_ca: |
            -----BEGIN CERTIFICATE-----
            MIICajCCAhGgAwIBAgIBATAKBggqhkjOPQQDBDBoMREwDwYDVQQKDAhNZWdhY29v
            bDEoMCYGA1UECwwfSW50ZXJuYWwgaG9zdHMgZm9yIEhUVFAgc2VydmVyczEpMCcG
            A1UEAwwgaHR0cC1ob3N0cy5pbnRlcm5hbHMubWVnYWNvb2wuY28wHhcNMTYwMjI2
            MjA0NjE5WhcNMzYwMjIxMjA0NjE5WjBoMREwDwYDVQQKDAhNZWdhY29vbDEoMCYG
            A1UECwwfSW50ZXJuYWwgaG9zdHMgZm9yIEhUVFAgc2VydmVyczEpMCcGA1UEAwwg
            aHR0cC1ob3N0cy5pbnRlcm5hbHMubWVnYWNvb2wuY28wVjAQBgcqhkjOPQIBBgUr
            gQQACgNCAARent2n6cX0eu+JCZqqAyBWZVO69K8WTJUCN2npPLZn7SUi1lFnTjZk
            wOhbSoyKFom/Bag0gLL9GAK87fGoi1L0o4GuMIGrMA4GA1UdDwEB/wQEAwIBBjAS
            BgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBSU8pZTaa/7U4Cn2yQUi1B0r+Sx
            AjAfBgNVHSMEGDAWgBSU8pZTaa/7U4Cn2yQUi1B0r+SxAjBFBgNVHR8EPjA8MDqg
            NKAyhjBodHRwczovL2h0dHAtaG9zdHMuaW50ZXJuYWxzLm1lZ2Fjb29sLmNvL2Ny
            bC5wZW2BAgBNMAoGCCqGSM49BAMEA0cAMEQCIDI01Ds9PC18w9qh4RtrLRq3jQ6s
            0Vx4ODYqLZ0Qy6HuAiBEc0HhV6oLbXRTkjBQfkVFKUtlrIbbtMBzeiluyW0dlw==
            -----END CERTIFICATE-----
        proxy_ca_crl: |
            -----BEGIN X509 CRL-----
            MIIBlzCCAT4CAQEwCgYIKoZIzj0EAwQwaDERMA8GA1UECgwITWVnYWNvb2wxKDAm
            BgNVBAsMH0ludGVybmFsIGhvc3RzIGZvciBIVFRQIHNlcnZlcnMxKTAnBgNVBAMM
            IGh0dHAtaG9zdHMuaW50ZXJuYWxzLm1lZ2Fjb29sLmNvFw0xNjAyMjYyMzEwMTBa
            Fw0xNjAzMTEyMzEwMTBaoIGkMIGhMIGSBgNVHSMEgYowgYeAFJTyllNpr/tTgKfb
            JBSLUHSv5LECoWykajBoMREwDwYDVQQKDAhNZWdhY29vbDEoMCYGA1UECwwfSW50
            ZXJuYWwgaG9zdHMgZm9yIEhUVFAgc2VydmVyczEpMCcGA1UEAwwgaHR0cC1ob3N0
            cy5pbnRlcm5hbHMubWVnYWNvb2wuY2+CAQEwCgYDVR0UBAMCAQEwCgYIKoZIzj0E
            AwQDRwAwRAIgFo1EjmgV1H+t/UaGDA/W/CZm0PYO1HWL3tKfSLrAUQ8CIA+y2+Qc
            jPDq5skMdAYI0xrKttBnjT4BRQxaW94iVJZ5
            -----END X509 CRL-----
        proxy_auth:
            key: |
                -----BEGIN EC PARAMETERS-----
                BgUrgQQACg==
                -----END EC PARAMETERS-----
                -----BEGIN EC PRIVATE KEY-----
                MHQCAQEEIFxaBU1XIqg17bU2YnPHgmvbSeL6WYXrrXaMP1QCyUI9oAcGBSuBBAAK
                oUQDQgAEmuaIqubCNaJdCnRngskG7s6BzQtqUIqiawqnwZHGJHDTasYzqA1+2L11
                s7iwYI6DLwxsi0pbzkjGTKnKtj2q/g==
                -----END EC PRIVATE KEY-----
            cert: |
                -----BEGIN CERTIFICATE-----
                MIICxDCCAmqgAwIBAgIBAjAKBggqhkjOPQQDBDBrMREwDwYDVQQKDAhNZWdhY29v
                bDEmMCQGA1UECwwdUHVibGljLWZhY2luZyBUTFMgdGVybWluYXRvcnMxLjAsBgNV
                BAMMJXRscy10ZXJtaW5hdG9ycy5pbnRlcm5hbHMubWVnYWNvb2wuY28wHhcNMTYw
                MjI2MjAyMzI5WhcNMTYwODI0MjAyMzI5WjBuMREwDwYDVQQKDAhNZWdhY29vbDEm
                MCQGA1UECwwdUHVibGljLWZhY2luZyBUTFMgdGVybWluYXRvcnMxMTAvBgNVBAMM
                KGV1LnRscy10ZXJtaW5hdG9ycy5pbnRlcm5hbHMubWVnYWNvb2wuY28wVjAQBgcq
                hkjOPQIBBgUrgQQACgNCAASa5oiq5sI1ol0KdGeCyQbuzoHNC2pQiqJrCqfBkcYk
                cNNqxjOoDX7YvXWzuLBgjoMvDGyLSlvOSMZMqcq2Par+o4H+MIH7MA4GA1UdDwEB
                /wQEAwIFoDAJBgNVHRMEAjAAMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcD
                AjAdBgNVHQ4EFgQUKbc5UHnvVOR1PBNujeiQ3PXt4n0wHwYDVR0jBBgwFoAUUHpG
                /X3tmXqbZVNAWSU/ifOSdDwwSgYDVR0fBEMwQTA/oDmgN4Y1aHR0cHM6Ly90bHMt
                dGVybWluYXRvcnMuaW50ZXJuYWxzLm1lZ2Fjb29sLmNvL2NybC5wZW2BAgBNMDMG
                A1UdEQQsMCqCKGV1LnRscy10ZXJtaW5hdG9ycy5pbnRlcm5hbHMubWVnYWNvb2wu
                Y28wCgYIKoZIzj0EAwQDSAAwRQIhAKRBXdE9JhdUqYFuBAiVWZ6IxeSZtll/7sUa
                hySFU2sUAiB6w9dAjnEPnWxvKMccIJM4YRF/eUhlLrZUpRPGb2IVtg==
                -----END CERTIFICATE-----
        key: |
            -----BEGIN RSA PRIVATE KEY-----
            MIIEpQIBAAKCAQEAx7FRExUQgEEBxjtPbiS8D7sQ22YoUADE8PPcvuOcFEyx5gPE
            OF7l8U00+lnL0iI+1wYowawz2lwTJZ5p7UQgZydbu7JzwZb+qSgdOCfG7pJfJEfH
            GzdC3DizcbbluphGtJTzJKubuxoS+A4HaCbkN4wJy7MZ49gSfNXxc4G1K2Kx7L6H
            qRlXu7szqj8YP+TRnPWWfdWNMAuXDwakdih3CI7TaREYeRW/ntTvfQR2EQdoAQ/R
            jBMY42HpiF8iu1OqHvEyY+NvOhr7Ftec8IrZLY2h7QGCLy3EnwlKl6TsqgYN6VSS
            4mf0xlQFi313sE+MfOEgFyAdeLQM9gmX7+6G8wIDAQABAoIBAQCgnI5P4cZW0XJC
            5Rs6xJL5uAST4jOUPTopbopigiDb9t+y196vVCxviyCMJ0MW7PJL8alANGe0PhAs
            VqBt9Dh3nyFZ8urFjtOebCQsMVoAMnwRayXKTwUYqQYy9N8K2EUuIwr4uInVz9/n
            4Si17Wnq/1g1nQS6y+P6wfykYXO8wwSQPraIqddiyVhoYxHWV6djwB2nQkG1RHGH
            iX6+e68dFeSCJD07OCVIdSelM7y40FFvNN1GkRg6VLUnTIEFFaTDH3aYKLXGNiUD
            K5NWuNeiwg2lYxxS6kA4+Kudxu2ylfelk82fBUEnevuvqHzLVDGB0NcwTYS1hMEE
            CbKfEaMxAoGBAPecGorLYGlqaoerXy74PuEF7BSVojeKkeWoiDf5yHfsx3iL2D1X
            nxTRxo8r+OlYCMoalEx2RmL/w0SLJ4idx/fhwT4pevI4E2af2Bu79cDSYHJ0cAXe
            AP7vVj6uAY2bn+Q1lMIy/TBlmDlqDaBMUCHB0If5n1FIs6hnvBFD675JAoGBAM51
            jgbnK/EHiyjpFdaw/ym7S2pV9jQr8jZWVya/vqF2mnKAW+FnP0n69tIlQCrQd3lO
            v7mASQSb3hg0M4QY5kTgq+cKDbyj8lI6X84fuNzfo4zeEuwS5l1ICMYNV35Ef8ka
            7BZux7zNgL/JZPDYZwjoWMOqEPpAuwM9KLHZTstbAoGBAOmQ+wiJp7xIgYzQfszT
            ppyk9XjFXWt+7vjv7O7AU/WsCM0RPT0/9fOxnddX50hVnpTmVZV6zBJ+qDdz/CrG
            iuassZhtkGgDtWlMxpICz2LAD/JnG3StYcsZAQXHJffqIP0n/dbiOir46oreG1Rm
            KABvzsE1Gq+WIMJud9zhcPLhAoGAW+pYHdijZn5eRQtoTpmkL/cTfzbgEqASCIDt
            8fFhtE6yOhHNVg96TLxvUGWHKMiAuEAH+VUUrPmbqhjran8PXVDNF2IRdY9j3Znh
            d0oGKkdib9+aewF7D8J3LX1ZG3zxix3yR5ZwVC0FidzmlJczX/LZOdsoDdHtsGZ1
            DKDbhIsCgYEA8Q9lasseAgnv2U1ZlwoWlHPne8Z3jdboErjPyyhrgZmKBaVjHYxC
            QDwxsFwASSByUUuUfRs8Pk9uiSZ207cJMry9qxkDfMab5HP9R5YuPwuOUl4aW/S4
            adS+IOSMt0seJcKwd2dW7QOGwqgStWVisht/E33S3sHjlJt+gLoHGuI=
            -----END RSA PRIVATE KEY-----
        cert: |
            -----BEGIN CERTIFICATE-----
            MIICqDCCAZACCQCezCLnLlSKPDANBgkqhkiG9w0BAQsFADAWMRQwEgYDVQQDEwtt
            ZWdhY29vbC5jbzAeFw0xNjAyMjYyMTEyNTFaFw0yNjAyMjMyMTEyNTFaMBYxFDAS
            BgNVBAMTC21lZ2Fjb29sLmNvMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
            AQEAx7FRExUQgEEBxjtPbiS8D7sQ22YoUADE8PPcvuOcFEyx5gPEOF7l8U00+lnL
            0iI+1wYowawz2lwTJZ5p7UQgZydbu7JzwZb+qSgdOCfG7pJfJEfHGzdC3Dizcbbl
            uphGtJTzJKubuxoS+A4HaCbkN4wJy7MZ49gSfNXxc4G1K2Kx7L6HqRlXu7szqj8Y
            P+TRnPWWfdWNMAuXDwakdih3CI7TaREYeRW/ntTvfQR2EQdoAQ/RjBMY42HpiF8i
            u1OqHvEyY+NvOhr7Ftec8IrZLY2h7QGCLy3EnwlKl6TsqgYN6VSS4mf0xlQFi313
            sE+MfOEgFyAdeLQM9gmX7+6G8wIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQBi8Cbk
            XZxxD1H5A20cg67/lX0gqAVVKx/iTgvjjz98wkRhM2RaUZmZDbebDknMzTVawz7P
            wA3IXe5hOeYoaXqx5giLcw1zvgffMFEDjdCWn1K+Zi3I/DoZ2JO7KPf2zgNC2PiX
            zgEJLtwqk1ihsbpoiMa1QQ1/7hjhE/tPnlMjO04qEHFRbRmCGm8vA0b2eGFH9usa
            mBgML7Xd/LP+r8eU0RBpjp6mPy6Px+e+PycPgcO/GVh1GxC80EmWaWhVP6x83oJq
            KTUN61I/cw0rpSll7t3wA77+xcYhJdNyi4HiuqILF0EMXpuSYtJ1+D5mjPgQ1Qqu
            ae7z0sS5zVQ9dFQD
            -----END CERTIFICATE-----

nginx:
    public: False
    default_cert: |
        -----BEGIN CERTIFICATE-----
        MIICqDCCAZACCQCezCLnLlSKPDANBgkqhkiG9w0BAQsFADAWMRQwEgYDVQQDEwtt
        ZWdhY29vbC5jbzAeFw0xNjAyMjYyMTEyNTFaFw0yNjAyMjMyMTEyNTFaMBYxFDAS
        BgNVBAMTC21lZ2Fjb29sLmNvMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
        AQEAx7FRExUQgEEBxjtPbiS8D7sQ22YoUADE8PPcvuOcFEyx5gPEOF7l8U00+lnL
        0iI+1wYowawz2lwTJZ5p7UQgZydbu7JzwZb+qSgdOCfG7pJfJEfHGzdC3Dizcbbl
        uphGtJTzJKubuxoS+A4HaCbkN4wJy7MZ49gSfNXxc4G1K2Kx7L6HqRlXu7szqj8Y
        P+TRnPWWfdWNMAuXDwakdih3CI7TaREYeRW/ntTvfQR2EQdoAQ/RjBMY42HpiF8i
        u1OqHvEyY+NvOhr7Ftec8IrZLY2h7QGCLy3EnwlKl6TsqgYN6VSS4mf0xlQFi313
        sE+MfOEgFyAdeLQM9gmX7+6G8wIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQBi8Cbk
        XZxxD1H5A20cg67/lX0gqAVVKx/iTgvjjz98wkRhM2RaUZmZDbebDknMzTVawz7P
        wA3IXe5hOeYoaXqx5giLcw1zvgffMFEDjdCWn1K+Zi3I/DoZ2JO7KPf2zgNC2PiX
        zgEJLtwqk1ihsbpoiMa1QQ1/7hjhE/tPnlMjO04qEHFRbRmCGm8vA0b2eGFH9usa
        mBgML7Xd/LP+r8eU0RBpjp6mPy6Px+e+PycPgcO/GVh1GxC80EmWaWhVP6x83oJq
        KTUN61I/cw0rpSll7t3wA77+xcYhJdNyi4HiuqILF0EMXpuSYtJ1+D5mjPgQ1Qqu
        ae7z0sS5zVQ9dFQD
        -----END CERTIFICATE-----
    default_key: |
        -----BEGIN RSA PRIVATE KEY-----
        MIIEpQIBAAKCAQEAx7FRExUQgEEBxjtPbiS8D7sQ22YoUADE8PPcvuOcFEyx5gPE
        OF7l8U00+lnL0iI+1wYowawz2lwTJZ5p7UQgZydbu7JzwZb+qSgdOCfG7pJfJEfH
        GzdC3DizcbbluphGtJTzJKubuxoS+A4HaCbkN4wJy7MZ49gSfNXxc4G1K2Kx7L6H
        qRlXu7szqj8YP+TRnPWWfdWNMAuXDwakdih3CI7TaREYeRW/ntTvfQR2EQdoAQ/R
        jBMY42HpiF8iu1OqHvEyY+NvOhr7Ftec8IrZLY2h7QGCLy3EnwlKl6TsqgYN6VSS
        4mf0xlQFi313sE+MfOEgFyAdeLQM9gmX7+6G8wIDAQABAoIBAQCgnI5P4cZW0XJC
        5Rs6xJL5uAST4jOUPTopbopigiDb9t+y196vVCxviyCMJ0MW7PJL8alANGe0PhAs
        VqBt9Dh3nyFZ8urFjtOebCQsMVoAMnwRayXKTwUYqQYy9N8K2EUuIwr4uInVz9/n
        4Si17Wnq/1g1nQS6y+P6wfykYXO8wwSQPraIqddiyVhoYxHWV6djwB2nQkG1RHGH
        iX6+e68dFeSCJD07OCVIdSelM7y40FFvNN1GkRg6VLUnTIEFFaTDH3aYKLXGNiUD
        K5NWuNeiwg2lYxxS6kA4+Kudxu2ylfelk82fBUEnevuvqHzLVDGB0NcwTYS1hMEE
        CbKfEaMxAoGBAPecGorLYGlqaoerXy74PuEF7BSVojeKkeWoiDf5yHfsx3iL2D1X
        nxTRxo8r+OlYCMoalEx2RmL/w0SLJ4idx/fhwT4pevI4E2af2Bu79cDSYHJ0cAXe
        AP7vVj6uAY2bn+Q1lMIy/TBlmDlqDaBMUCHB0If5n1FIs6hnvBFD675JAoGBAM51
        jgbnK/EHiyjpFdaw/ym7S2pV9jQr8jZWVya/vqF2mnKAW+FnP0n69tIlQCrQd3lO
        v7mASQSb3hg0M4QY5kTgq+cKDbyj8lI6X84fuNzfo4zeEuwS5l1ICMYNV35Ef8ka
        7BZux7zNgL/JZPDYZwjoWMOqEPpAuwM9KLHZTstbAoGBAOmQ+wiJp7xIgYzQfszT
        ppyk9XjFXWt+7vjv7O7AU/WsCM0RPT0/9fOxnddX50hVnpTmVZV6zBJ+qDdz/CrG
        iuassZhtkGgDtWlMxpICz2LAD/JnG3StYcsZAQXHJffqIP0n/dbiOir46oreG1Rm
        KABvzsE1Gq+WIMJud9zhcPLhAoGAW+pYHdijZn5eRQtoTpmkL/cTfzbgEqASCIDt
        8fFhtE6yOhHNVg96TLxvUGWHKMiAuEAH+VUUrPmbqhjran8PXVDNF2IRdY9j3Znh
        d0oGKkdib9+aewF7D8J3LX1ZG3zxix3yR5ZwVC0FidzmlJczX/LZOdsoDdHtsGZ1
        DKDbhIsCgYEA8Q9lasseAgnv2U1ZlwoWlHPne8Z3jdboErjPyyhrgZmKBaVjHYxC
        QDwxsFwASSByUUuUfRs8Pk9uiSZ207cJMry9qxkDfMab5HP9R5YuPwuOUl4aW/S4
        adS+IOSMt0seJcKwd2dW7QOGwqgStWVisht/E33S3sHjlJt+gLoHGuI=
        -----END RSA PRIVATE KEY-----
