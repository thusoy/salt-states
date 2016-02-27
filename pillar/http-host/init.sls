http-host:
    client-trusted-roots: |
        # tls-terminators.internals.megacool.co
        -----BEGIN CERTIFICATE-----
        MIICKDCCAc6gAwIBAgIBATAKBggqhkjOPQQDBDBrMREwDwYDVQQKDAhNZWdhY29v
        bDEmMCQGA1UECwwdUHVibGljLWZhY2luZyBUTFMgdGVybWluYXRvcnMxLjAsBgNV
        BAMMJXRscy10ZXJtaW5hdG9ycy5pbnRlcm5hbHMubWVnYWNvb2wuY28wHhcNMTYw
        MjI3MDA1ODIyWhcNMzYwMjIyMDA1ODIyWjBrMREwDwYDVQQKDAhNZWdhY29vbDEm
        MCQGA1UECwwdUHVibGljLWZhY2luZyBUTFMgdGVybWluYXRvcnMxLjAsBgNVBAMM
        JXRscy10ZXJtaW5hdG9ycy5pbnRlcm5hbHMubWVnYWNvb2wuY28wVjAQBgcqhkjO
        PQIBBgUrgQQACgNCAAQAky/txQfqbssQWA+iUZEAYozU9MHRnz3AaE84yN6ThF9T
        spQTOOziWin3rbUiI68oxXd5Ly7KSaHMF/4JuYEOo2YwZDAOBgNVHQ8BAf8EBAMC
        AQYwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUuWMDunAdRDVlChRjSvtL
        XcR5C9UwHwYDVR0jBBgwFoAUuWMDunAdRDVlChRjSvtLXcR5C9UwCgYIKoZIzj0E
        AwQDSAAwRQIhAI06olC5Yq6s5FnPbTRa0+a2fM7npsXIiXsuXlOj/q9kAiAcEVxB
        vpm9EKSYCFU/DQQxy3Pmntau97A9p/dfa4+plQ==
        -----END CERTIFICATE-----
    # client-ca-crl
    meowth:
        key: |
            -----BEGIN EC PARAMETERS-----
            BgUrgQQACg==
            -----END EC PARAMETERS-----
            -----BEGIN EC PRIVATE KEY-----
            MHQCAQEEIFlYRa7w52Fdew2UlUPDVbyUDcPgzrl1rXOGrOimU2V4oAcGBSuBBAAK
            oUQDQgAEamYGUojWvxtrB+Jxt32225timlto8XWL1ITc9jTQO7XFi3GLOW4j3uqY
            CtHAT0OTlSFLbzyAkXSS+4UTwzrObw==
            -----END EC PRIVATE KEY-----
        cert: |
            -----BEGIN CERTIFICATE-----
            MIICUTCCAfegAwIBAgIBAzAKBggqhkjOPQQDBDBbMREwDwYDVQQKDAhNZWdhY29v
            bDEbMBkGA1UECwwSSW50ZXJhbCBIVFRQIEhvc3RzMSkwJwYDVQQDDCBodHRwLWhv
            c3RzLmludGVybmFscy5tZWdhY29vbC5jbzAeFw0xNjAyMjcwMTIxMDhaFw0xNjA4
            MjUwMTIxMDhaMGIxETAPBgNVBAoMCE1lZ2Fjb29sMRswGQYDVQQLDBJJbnRlcmFs
            IEhUVFAgSG9zdHMxMDAuBgNVBAMMJ21lb3d0aC5odHRwLWhvc3RzLmludGVybmFs
            cy5tZWdhY29vbC5jbzBWMBAGByqGSM49AgEGBSuBBAAKA0IABGpmBlKI1r8bawfi
            cbd9ttubYppbaPF1i9SE3PY00Du1xYtxizluI97qmArRwE9Dk5UhS288gJF0kvuF
            E8M6zm+jgacwgaQwDgYDVR0PAQH/BAQDAgWgMBMGA1UdJQQMMAoGCCsGAQUFBwMB
            MAkGA1UdEwQCMAAwHQYDVR0OBBYEFImfyfGXDS4ciQWLk+VMnalUQSAGMB8GA1Ud
            IwQYMBaAFFmwt0L+NCUjSeLKHJ5/UK9ZczNmMDIGA1UdEQQrMCmCJ21lb3d0aC5o
            dHRwLWhvc3RzLmludGVybmFscy5tZWdhY29vbC5jbzAKBggqhkjOPQQDBANIADBF
            AiEA7x3lAOvIRIMyHqNI9MnVPjB1XzojvwxOPdDwXvprCUoCIEZ4YCY3azs750gk
            i4xX3QhkuKqkrpUmos80ZUeMyHXu
            -----END CERTIFICATE-----


tls-terminator:
    megacool.co:
        backend: https://internal.megacool.co:8443
        proxy_ca: |
            -----BEGIN CERTIFICATE-----
            MIICCTCCAa6gAwIBAgIBATAKBggqhkjOPQQDBDBbMREwDwYDVQQKDAhNZWdhY29v
            bDEbMBkGA1UECwwSSW50ZXJhbCBIVFRQIEhvc3RzMSkwJwYDVQQDDCBodHRwLWhv
            c3RzLmludGVybmFscy5tZWdhY29vbC5jbzAeFw0xNjAyMjcwMDU4MDRaFw0zNjAy
            MjIwMDU4MDRaMFsxETAPBgNVBAoMCE1lZ2Fjb29sMRswGQYDVQQLDBJJbnRlcmFs
            IEhUVFAgSG9zdHMxKTAnBgNVBAMMIGh0dHAtaG9zdHMuaW50ZXJuYWxzLm1lZ2Fj
            b29sLmNvMFYwEAYHKoZIzj0CAQYFK4EEAAoDQgAEoNS00mDFwv3GQAYjqxaOG74X
            Mv1jjVxHR/Fs353u1ClK+Mv2g3z740RG6ipWG+nCGNTmdhI+JEI0Ad2DryEg+KNm
            MGQwDgYDVR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYE
            FFmwt0L+NCUjSeLKHJ5/UK9ZczNmMB8GA1UdIwQYMBaAFFmwt0L+NCUjSeLKHJ5/
            UK9ZczNmMAoGCCqGSM49BAMEA0kAMEYCIQCfOs7bkDiT3pPfKUjzXtwYeHhm9Nsp
            K5uJF64Hy/QyjAIhAPElA2Wu/AdNU8FWQfZUakwHeth/dPPrU5zqiYKiwIzF
            -----END CERTIFICATE-----
        proxy_ca_crl: |
            -----BEGIN X509 CRL-----
            MIIBkzCCATgCAQEwCgYIKoZIzj0EAwQwWzERMA8GA1UECgwITWVnYWNvb2wxGzAZ
            BgNVBAsMEkludGVyYWwgSFRUUCBIb3N0czEpMCcGA1UEAwwgaHR0cC1ob3N0cy5p
            bnRlcm5hbHMubWVnYWNvb2wuY28XDTE2MDIyNzAxMTkxNVoXDTE2MDMxMjAxMTkx
            NVowFDASAgECFw0xNjAyMjcwMTE5MDlaoIGVMIGSMIGDBgNVHSMEfDB6gBRZsLdC
            /jQlI0niyhyef1CvWXMzZqFfpF0wWzERMA8GA1UECgwITWVnYWNvb2wxGzAZBgNV
            BAsMEkludGVyYWwgSFRUUCBIb3N0czEpMCcGA1UEAwwgaHR0cC1ob3N0cy5pbnRl
            cm5hbHMubWVnYWNvb2wuY2+CAQEwCgYDVR0UBAMCAQIwCgYIKoZIzj0EAwQDSQAw
            RgIhANwGvbj9wx+TO/ixx+qGFOy9IOqyHOkbmPfZffhGhkNbAiEA554ZG8v3pxwv
            LAVvfXG8hNalTwENd3Zv43ghJIZTGd4=
            -----END X509 CRL-----
        proxy_auth:
            key: |
                -----BEGIN EC PARAMETERS-----
                BgUrgQQACg==
                -----END EC PARAMETERS-----
                -----BEGIN EC PRIVATE KEY-----
                MHQCAQEEIE71/ktBZ97fG0TVD+8+0MnUL7EojwkbADDV0k5E+wJDoAcGBSuBBAAK
                oUQDQgAEc2KFjbFaq5T28upxPj1d7j9eLFWAacHU+ywqfRiCYhtVCXN+BHk2CijP
                7JU91VvzyUaTbjteBQtkgzCD9lXrDg==
                -----END EC PRIVATE KEY-----
            cert: |
                -----BEGIN CERTIFICATE-----
                MIICcTCCAhigAwIBAgIBAjAKBggqhkjOPQQDBDBrMREwDwYDVQQKDAhNZWdhY29v
                bDEmMCQGA1UECwwdUHVibGljLWZhY2luZyBUTFMgdGVybWluYXRvcnMxLjAsBgNV
                BAMMJXRscy10ZXJtaW5hdG9ycy5pbnRlcm5hbHMubWVnYWNvb2wuY28wHhcNMTYw
                MjI3MDExNTUwWhcNMTYwODI1MDExNTUwWjBwMREwDwYDVQQKDAhNZWdhY29vbDEm
                MCQGA1UECwwdUHVibGljLWZhY2luZyBUTFMgdGVybWluYXRvcnMxMzAxBgNVBAMM
                KnNmbzEudGxzLXRlcm1pbmF0b3JzLmludGVybmFscy5tZWdhY29vbC5jbzBWMBAG
                ByqGSM49AgEGBSuBBAAKA0IABHNihY2xWquU9vLqcT49Xe4/XixVgGnB1PssKn0Y
                gmIbVQlzfgR5Ngooz+yVPdVb88lGk247XgULZIMwg/ZV6w6jgaowgacwDgYDVR0P
                AQH/BAQDAgWgMBMGA1UdJQQMMAoGCCsGAQUFBwMCMAkGA1UdEwQCMAAwHQYDVR0O
                BBYEFIJLkEdPf9g8/8A1KVu2fT5qeg9YMB8GA1UdIwQYMBaAFLljA7pwHUQ1ZQoU
                Y0r7S13EeQvVMDUGA1UdEQQuMCyCKnNmbzEudGxzLXRlcm1pbmF0b3JzLmludGVy
                bmFscy5tZWdhY29vbC5jbzAKBggqhkjOPQQDBANHADBEAiBGxlkiY9z9xO2ORT+x
                LgaAEdyB5BtDSOdzxDNEdID5+AIgEKGmElnA6RgSIbojyWeObLK1oPTmsT+9J9p+
                HxemKpw=
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
