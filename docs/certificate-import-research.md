# SideStore Full P12 import compatibility

## Findings

The current SideStore `develop` implementation exports a full PKCS#12 file in
`SideStore/Views/Settings/Advanced/Certificates/CertificateExporter.swift`.
Its `shareP12` method calls `cert.encryptedP12Data(password:)` and shares the
returned bytes with a `.p12` filename.

The same SideStore source imports `SideSign` and `CodeSignKit`. Its
`CertificateManager.parse(_:password:)` constructs an `ALTCertificate` from
the P12 data instead of calling Apple's `SecPKCS12Import`.

SideSign exposes a dedicated `PKCS12Parser.extract(_:password:)` API returning
certificate DER and private-key DER. It also exposes `PKCS12Parser.create`
for producing a PKCS#12 container from those components. Its README documents
support for unencrypted, 3DES, PBES2 and AES PKCS#12 cipher suites.

This establishes a concrete compatibility lead: SideStore's own certificate
stack uses its SideSign/CodeSignKit parser and model. It does **not** yet prove
which exact PKCS#12 algorithm or encoding caused Apple's `errSecDecode` on the
user's exported file. File size and the ASN.1 sequence marker alone cannot
establish corruption.

## Integration constraints

- SideSign's README declares GPL-3.0. URX Core must not silently add it as a
  linked dependency without first deciding whether the project's distribution
  and licensing can comply.
- SideSign is much broader than a PKCS#12 parser: it also contains app bundle
  signing, Apple Developer API and archive functionality. URX should not pull
  in unrelated capabilities merely to parse a certificate.
- The parser returns private-key material as DER. Any future adapter must keep
  processing local, avoid logs or network transfer of key bytes, validate that
  both certificate and private key are present, and only persist material after
  successful verification.
- A certificate does not grant jailbreak privileges or authorize execution
  outside iOS's supported signing and launch model.

## URX implementation decision

Do not treat `errSecDecode` as proof that the user's SideStore export is
corrupt. Keep Apple's Security framework as the final identity validation
boundary. Before implementation, evaluate a narrowly scoped PKCS#12 parser
whose license is compatible with URX, or obtain explicit permission and settle
the GPL-3.0 implications before linking SideSign.

A future adapter should follow this sequence:

1. Read the selected file without changing its bytes.
2. Attempt Apple's native PKCS#12 import.
3. If native decoding fails, use an approved compatible parser to extract the
   certificate and private key locally.
4. Re-encode a standards-compatible PKCS#12 container.
5. Re-import that container with Apple's Security framework.
6. Save only after Apple returns a valid `SecIdentity`; never save an
   unverified container as an imported identity.

## Sources inspected

- SideStore `CertificateExporter.swift`:
  https://github.com/SideStore/SideStore/blob/develop/SideStore/Views/Settings/Advanced/Certificates/CertificateExporter.swift
- SideStore `CertificateManager.swift`:
  https://github.com/SideStore/SideStore/blob/develop/SideStore/Core/Certificates/CertificateManager.swift
- SideSign `PKCS12Parser.swift`:
  https://github.com/SideStore/SideSign/blob/main/Sources/Certificates/PKCS12Parser.swift
- SideSign README and license:
  https://github.com/SideStore/SideSign
