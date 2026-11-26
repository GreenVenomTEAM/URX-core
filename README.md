# Unc0veR rEb0rnEd X Core

**URX Core** is an experimental, app-contained iOS guest-environment research project by **GreenVenom Team**.

## Current status

This repository starts with a SwiftUI shell and a safe foundation. It is not a working iOS virtual machine, jailbreak, Sileo port, or tweak runtime yet.

## Design principles

- Keep guest data inside the app's own container.
- Never modify the host operating system, SpringBoard, kernel, or other apps.
- Treat imported packages as untrusted data; inspect metadata only until a deliberately sandboxed runtime exists.
- Never claim general jailbreak-tweak compatibility.
- Handle signing identities locally and ephemerally. Never upload certificates, private keys, provisioning profiles, or passwords.

A normal iOS app cannot grant itself host-kernel privileges, escape its app sandbox, inject into SpringBoard, or load arbitrary privileged jailbreak tweaks. A signing certificate does not grant those capabilities.

The first milestones are a guest workspace, package metadata inspection, dependency modeling, and a limited extension interface. Original Sileo compatibility is an investigation, not a promise.

## Build

Install XcodeGen, then run:

    xcodegen generate
    xcodebuild -project URXCore.xcodeproj -scheme URXCore -sdk iphonesimulator -configuration Debug build

## Layout

- Sources/: SwiftUI app shell and local guest workspace.
- docs/architecture.md: architecture, threat model, and compatibility limits.
- .github/workflows/ios-build.yml: simulator build validation.

No license has been granted yet. All rights remain with their respective authors.
