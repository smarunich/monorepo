export FOLDER="."

cat >"${FOLDER}/managementplane_values.yaml" <<EOF
image:
  registry: ea1p2demotsbacrqsnstv6qddaupjrc.azurecr.io
  tag: 1.5.0
secrets:
  tsb:
    adminPassword: Tetrate123
    cert: |
      -----BEGIN CERTIFICATE-----
      MIIDIzCCAgugAwIBAgIQeYdv8tQ1+IwTNlrYkioJQDANBgkqhkiG9w0BAQsFADAv
      MRUwEwYDVQQKEwxjZXJ0LW1hbmFnZXIxFjAUBgNVBAMTDXNlbGZzaWduZWQtY2Ew
      HhcNMjIwNjExMDIxNzQ4WhcNMjQxMTI3MDIxNzQ4WjAAMIIBIjANBgkqhkiG9w0B
      AQEFAAOCAQ8AMIIBCgKCAQEA3weuy6C/TDy44WvzP5nGRIF9UEY0d+AZuu2BKDdb
      XdbL6IHF7uaYKQKqpBLhfDMaAzCQQmcfiKVemvFiVvzxFyRB5qPIbldwgfwwG/3L
      AbkOeJJxBc2GT/3bacS9J7jwtUbFGyOvA39SopZkd98oy876yD/v/Mc7Dvt0YPJa
      1mydVfEIhJQUyp4dCRAavRmEe8bdM2zTWM2Bf2QLtHvg5eg633O95s6vpd8JupoD
      pX6JFRXVxF9MLUlvz9DfdZcwN9pjJHoTk7op4lrxcdTE41uupJ0Z3EapObUzfrbT
      xk6QzzZc3+IZrDMTXwsVjIFWh4gKRDnOLdKg6DWIpzKT6wIDAQABo2owaDAOBgNV
      HQ8BAf8EBAMCBaAwDAYDVR0TAQH/BAIwADAfBgNVHSMEGDAWgBS450is6L0euG8R
      yGjS2NRX8Qp6JTAnBgNVHREBAf8EHTAbghllYTFwMmRlbW8uY3gudGV0cmF0ZS5p
      bmZvMA0GCSqGSIb3DQEBCwUAA4IBAQBi2h7BNxVBP9Qh3qIOv3Brcqw1GlgIcTqL
      oNd56ENneGDv5K29am94dGI9E7LFMeuxzXPmySjpdt6ZngUdViR7zOo5+FBA2KBK
      QDzPFnNWx/GpUo4GSNMXfsetEl3Ri02k3tRKlZKSXU0KvhNVaBhe8UmeqMr6juiP
      ZWrqqjaAhDrf074HO8cgOfy4gNYSlMDvczjpMu6Uf6gBkwmc0JqMIUJYL/V3xIS/
      vcaxUyrSigSTULazByBt8NNbwVCg/ZhgVrtxweQ/fxUsPUNIYx3fjmWDClyUkwiy
      a9NSkuyXlKWO2FGKVhGBWI01MWZfCDrDTVh6ek4qM9+gCSgKUYuP
      -----END CERTIFICATE-----
    key: |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEowIBAAKCAQEA3weuy6C/TDy44WvzP5nGRIF9UEY0d+AZuu2BKDdbXdbL6IHF
      7uaYKQKqpBLhfDMaAzCQQmcfiKVemvFiVvzxFyRB5qPIbldwgfwwG/3LAbkOeJJx
      Bc2GT/3bacS9J7jwtUbFGyOvA39SopZkd98oy876yD/v/Mc7Dvt0YPJa1mydVfEI
      hJQUyp4dCRAavRmEe8bdM2zTWM2Bf2QLtHvg5eg633O95s6vpd8JupoDpX6JFRXV
      xF9MLUlvz9DfdZcwN9pjJHoTk7op4lrxcdTE41uupJ0Z3EapObUzfrbTxk6QzzZc
      3+IZrDMTXwsVjIFWh4gKRDnOLdKg6DWIpzKT6wIDAQABAoIBAFSjjsM6Kr7c4HCz
      zelaCzMeTRc0vV6szjbxQS2o7GSNSm7fKOWD30TY/Tcs7yN6JSoGuQhqKD5sO53j
      cyV98mSM3vGPQFYXmtvJf9xvkSYDO6moMXo5R/p9ZVIbVomHltnElLK69QUHwa1w
      E4qmRs4pq2RpV0L/vLrv1HeiIbTzZ30Krhlp1fcw6Zim8mcRgArmCeZcd8mDoitN
      JDnmUkd314xXlZ7NPpPEwYMuTKhMxaw3q+b9fdCneimSqUxT/VefRxujjw+wpMTI
      Os4y/KixyFU5FyVbl6IfeAFX3RIEwgVdJX/dwlcsP3YBvRWTmyB+Oy5V6JZbNsK1
      C6jS0/ECgYEA4FPq1pIHPGotqEajjZJGlJMR1iL6KIH0K/Ktv8ndYeX5+sk3RbH2
      o2tus0VN/F1KoCLTV78qFU+pk4DlZ2aE0cHKxsPSABH/afGwVAXniFQ8V4dRHnCc
      bdYe+tUiFAH63sCU4dK5sktQiWsRttqYMwkuuUS5SwkXk1JHUyCAXAkCgYEA/oTb
      tCTiWKDtSGkynwk1KcXVTxIckwAmoOAVRqVfKSWktLS3yAvOgy+GUigEqv+EyICm
      rychQgrj+3cLTpFEMOhpPFqeMAbCvieu5AxrRvVZXL6ltBBor3+NWOxIIhkk2eaJ
      kjiXk92xccrfJGGYw0XDk1d0qmtVS03RpvfIFVMCgYA7V9fDBYRmhgwn/O/dTrnf
      KfzI8h3NQ3uNeLhgCQ3IjScRIdO+WzLMzmnNgOL9hMxuCmhwSQDf/F/2xl1peiRe
      vO5goILYQ+qWYzprL9itJuODoCdkbxPitochgepu8oskDDwWdUFsmiHnCGz6O1+R
      +Lbkifqej/wtm9GEew+ZyQKBgQDnYGxCdg12uMU9QLUOMtarpPdnrHVhhY+YTF3L
      HWdHBruWs3snVuRkCf44Db1Ano1doObm79GiMjhTUENtJ04wj/erME4CJwM+zuCE
      3G1h0oVsdLw613fzoyciIZrptKX1mUiTLvNNLwqzAdSdREQVsQQ8nBKpIm4lyRbA
      jRzNlQKBgEL5DVppVazpU6CUQt+Tp8kwNK8xZmbL4hLQdYASkH6DpYXRKKKm9ZJ2
      OJ9Qqtm+Pd13/p/nkFBv6wvEkR8KQvY2pcdX3vmaSFGWetxyPYxZenU+is8HxkWI
      RiYeuP5ZNfqcOD3pqnuIMX7u0k3Y2zxnikA9ckZkgRrRaYqKyIcM
      -----END RSA PRIVATE KEY-----
  xcp:
    autoGenerateCerts: true
    central:
      additionalDNSNames:
        - ea1p2demo.cx.tetrate.info
    rootca: |
      -----BEGIN CERTIFICATE-----
      MIIDKjCCAhKgAwIBAgIQUOuxDuMlrCo47pDvqUEpiTANBgkqhkiG9w0BAQsFADAv
      MRUwEwYDVQQKEwxjZXJ0LW1hbmFnZXIxFjAUBgNVBAMTDXNlbGZzaWduZWQtY2Ew
      HhcNMjIwNjExMDIxNjQzWhcNMjQxMTI3MDIxNjQzWjAvMRUwEwYDVQQKEwxjZXJ0
      LW1hbmFnZXIxFjAUBgNVBAMTDXNlbGZzaWduZWQtY2EwggEiMA0GCSqGSIb3DQEB
      AQUAA4IBDwAwggEKAoIBAQDXgA7d1Ehd+h+bVy+r3BRGIDNoM3WL3jfj3V+VOD8F
      aA6qjJpyBNwIeGY0NJyrv4NfeRxsEA3LqSOQdqDBxb5a7HSYwq7bphoP4vyj4+0r
      9Amc7lfOzBNpr7ed/J0xFiEfg3jkt61VW9XmZxa3EfeV7deFV0dz4XneukPRe6Cm
      rOfkRsPmMRYrajnzJFQIn+HuxzmizcbGse+yRlTbhgeBKrOdcnuPJpIPwm4Iry3G
      MK3e/1cQIVYo6GKky9mcxZB7No/m3OliJQwEj9A6br5+5pW7gXlChOyRQfonIioe
      WuuvNeGQ8IqebO2xQRlBighgC01Q12/8aKVpnG3FH7mnAgMBAAGjQjBAMA4GA1Ud
      DwEB/wQEAwICpDAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBS450is6L0euG8R
      yGjS2NRX8Qp6JTANBgkqhkiG9w0BAQsFAAOCAQEAQdgu8sA9xBH/DfqdO5VpzcuI
      7a7Z5UhmOQXxmI+4KGbNrFI7Zc+C1xYG4F0K9jD5KRUnrXSb0213gfxTdJ0wllAi
      AOWHb7o3LsLOGwM98lxGliEf3dj4sBZhKD7hWsxfGt4fzzqWjwy/k5366rVSrFhr
      p5HqqFhFpgzwD95gAs5ci3kG8LzHBvpKwSTw3oyLhCWv3+iPyFOdqQMAqASFT70b
      Nb5M0cMClXgQHuG1sRsUFzk2R8KOcoHSasAjmhctFsC3xmP6QfJWCqEJmW/v4ykW
      k0FdG1XZDjaLRPyxn4NIwj+7eGLrBjTd2XsUJ9wf4w5KlfbV/zkFcjzQ64KAYg==
      -----END CERTIFICATE-----
    rootcakey: |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEogIBAAKCAQEA14AO3dRIXfofm1cvq9wURiAzaDN1i943491flTg/BWgOqoya
      cgTcCHhmNDScq7+DX3kcbBANy6kjkHagwcW+Wux0mMKu26YaD+L8o+PtK/QJnO5X
      zswTaa+3nfydMRYhH4N45LetVVvV5mcWtxH3le3XhVdHc+F53rpD0Xugpqzn5EbD
      5jEWK2o58yRUCJ/h7sc5os3GxrHvskZU24YHgSqznXJ7jyaSD8JuCK8txjCt3v9X
      ECFWKOhipMvZnMWQezaP5tzpYiUMBI/QOm6+fuaVu4F5QoTskUH6JyIqHlrrrzXh
      kPCKnmztsUEZQYoIYAtNUNdv/GilaZxtxR+5pwIDAQABAoIBADNA5shFq+yGB6xn
      gRQL5NqE4BUhYAyjDoHobcpMtVhw1kQj6rvBgh+VmyFBfh2vD+zOHj9pVg6hLK84
      N6W+hTaU1Gpcqz/ccohiwRmtpQP2J68mVMX/bYKOY0p1AWHiVIBtQXyMXvJVRDtn
      O1TRNiR3i/HPv1PFRbn+bRDOqXfaadMGP8LO1gQGBxDsfn4JEXSl+BCntHV81Qu6
      1EHyxNz17tmQ8NKLS55mg4HYW+Zowr3c9+G4yzJCRnSfzznRMdB7G6bO2/Nc4Vn/
      RN/73e3aXcnJsRSSSlwCEKYRxwOfkoTO+aoNkDcezUEvrurbOWGM/BY6RudN8N22
      vcXuREkCgYEA20QmUph6JYerRkIsHya51WUojbndY13CZC/coTQ7nrUJFRkfFIE6
      DtrWP+nOZzw1u6i/BdwCIV+xsz4El8xoTu/vw+0gJDNDTP75I+IQgU0LZdL71827
      dPZYrm8zXDLD9safEwRRuENJQBQTXDgpxqVNI553sdXJBacJAU9JDo0CgYEA+5pk
      wNgCxbF99f3O2CCx0BG8BpvuUSjk3FKKBjhlUJv/ACpb3vUnljbXjZ61MMoOPeZN
      4zew9B/CkpRAfBNmYJtn+JFjP07URE3cMqfyRPv7Fpzl9ZNHuB0MM8leORip7Irh
      46uGygBdLBhPW0W/gwB9QuujaEKx0aljU4zyRgMCgYBj5T6YbsNnidHsZoV3g8sy
      f63kNAO7G6JOxsd74jIvckc7B4DzdJSg4+6sm7bfrbzFTHILF1sZHWH2SZEKH6R+
      Ii5YUxZLp9dHovqa8ImYfyNsNp1qil6XQQzSG/OIU9CYA5HBtjwM+QrMWNkhMK1H
      xVPJoI7jxISbQKiHojmkmQKBgD/yqOL+xA2dJCeun7D89lSs/T4sybClFS4OaHhW
      QyHu1Cwll/4eDza1r6mWCfVhlacT7v3uPLJ/lAOPXKhsgdvSA+YAhdokXf0SUQIq
      /3+bD+FadXQqP9NCxsQuzRzz8NRnJCyqfvK+ju/TKfBH1Pol2LB2lay9LtbcF5u3
      uigjAoGAYuHUACuvJOyUrwJRXFXBoV3ForHah0b2uJxSj0NIsP2qcDFw/ExgmO4F
      qONBkfMfGo3qemBNNcw26IUSciPyIfsg261qYWORim9xW839QbX/ppDmF1qDs9uk
      75SfXxl5kzKSig8nspBqxdCXbilVtxcFbRFZI+KA0yzGvcO3Ukw=
      -----END RSA PRIVATE KEY-----
spec:
  components:
    internalCertProvider:
      certManager:
        managed: EXTERNAL
    xcp:
      centralAuthModes:
        jwt: true
  hub: ea1p2demotsbacrqsnstv6qddaupjrc.azurecr.io
  organization: tetrate
  telemetryStore:
    elastic:
      host: 20.84.24.147
      port: 9200
      protocol: https
      selfSigned: true
      version: 7
EOF