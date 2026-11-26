# URX Core architecture

## Objective
Build an app-contained guest userspace prototype. The host iOS installation remains the trusted boundary and is never modified.

## Components
1. Host app shell: SwiftUI navigation, diagnostics, and user consent.
2. Guest workspace: files stored under the app's Application Support directory.
3. Package metadata reader (planned): parse Debian control metadata and dependencies as data only.
4. Dependency model (planned): resolve package relationships without running maintainer scripts.
5. Extension API (planned): explicit, capability-limited extension points implemented by the host app.
6. Identity inspector: optional local inspection of a PKCS#12 signing identity; no upload or persistent private-key storage.

## Security boundaries
- No kernel exploits, privilege escalation, sandbox escape, code injection into system processes, or host SpringBoard modification.
- No execution of untrusted package maintainer scripts.
- No automatic installation of certificates or profiles.
- Treat package archives and metadata as untrusted input; validate sizes, paths, and formats before parsing.
- Guest files must remain under the app container. Reject path traversal and symbolic-link escapes in future archive handling.
- Do not log secrets or certificate material.

## Sileo and tweak compatibility
Sileo is a package manager, not a virtual machine. Porting its UI alone would not provide the system services, package database, filesystem layout, or privileged execution environment expected by jailbreak packages. Compatibility must be evaluated dependency by dependency. Do not advertise arbitrary .deb or jailbreak tweak support unless each supported package has been audited and can run entirely within the documented guest boundary.

## Milestones
- [x] SwiftUI app shell.
- [x] Create a private guest workspace directory.
- [x] Local PKCS#12 identity inspection without persistence.
- [ ] Debian control-file metadata parser (no script execution).
- [ ] Package archive validation and safe extraction design.
- [ ] Dependency graph model.
- [ ] Capability-limited guest extension API.
- [ ] Investigate Sileo reuse, licenses, and runtime assumptions.
