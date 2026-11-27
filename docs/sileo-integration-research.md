# Sileo / Nyxian integration research

Status: architecture audit, 2026-11-27

## Goal

Investigate a maintainable route to embed or adapt Sileo's package-manager experience inside URX Core, using an isolated guest environment. This document records source-level findings and the proposed boundaries. It is not a claim that Sileo is already integrated.

## Sileo source audit

Upstream: https://github.com/Sileo/Sileo

Sileo is an APT frontend, not only a UI. The repository separates at least:

- UI: package, source, category, detail, downloads and settings screens (Sileo/UI).
- Repository model and refresh orchestration (Sileo/Backend/Repo Manager/RepoManager.swift, Sileo/Backend/Objects/Repo.swift).
- Package models and control-file parsing (Sileo/Backend/Objects, Control File Parser).
- Dependency resolution (Sileo/Backend/Dependency Resolver).
- Downloading and decompression (Download Manager, Decompression).
- APT and dpkg integration (APT Wrapper, DPKG Wrapper).
- A root helper / daemon path used by the normal jailbreak build.

The iOS application target is not a drop-in Swift package. It is an Xcode project with multiple targets, an Evander dependency and a DepictionKit submodule. The regular device build also expects a package-management environment and privileged helper integration. The source has a sandbox/demo conditional, but its APT operations are deliberately unavailable there; this is evidence that copying the UI alone does not supply a working package backend.

Relevant upstream files:
- https://github.com/Sileo/Sileo/blob/main/Sileo/Backend/Repo%20Manager/RepoManager.swift
- https://github.com/Sileo/Sileo/blob/main/Sileo/Backend/Objects/Repo.swift
- https://github.com/Sileo/Sileo/blob/main/Sileo/Backend/APT%20Wrapper/APTWrapper.swift
- https://github.com/Sileo/Sileo/blob/main/README.md

### Important repository discovery finding

Sileo's own RepoManager adds Havoc as a default source using the root URL https://havoc.app. A normal root URL is represented as a flat APT source with suite ./ and no components.

During refresh, Sileo:
1. Requests Release from the repository's effective base URL.
2. For non-flat repositories, reads the advertised architectures and components.
3. For flat repositories, resolves Packages directly from the base URL.
4. Tries package-index suffixes in this order: .zst, .xz, .lzma, .bz2, .gz, then uncompressed.
5. Separately retrieves Release.gpg and performs signature verification in its normal environment.

This explains a likely reason URX Core currently rejects Havoc: our first discovery implementation does not mirror Sileo's flat-source refresh contract, and it only supports gzip/uncompressed index data. In particular, it does not yet support zstd, xz, lzma or bzip2 index decompression. This should be fixed at the repository engine level, not by hardcoding Havoc.

## Nyxian / Switzach research

Official project information:
- https://nyxian.app/Nyxian/
- https://emexlab.org/Nyxian/docs/switzach/
- https://github.com/emexlab/Nyxian

The documented architecture is materially different from a conventional jailed app. Nyxian describes a bootloader, a userspace microkernel/runtime, a guest process environment and the ability to boot a separate ROM slot. Its public documentation describes process/subprocess services, a guest filesystem and permissions, and a separate ROM with its own kernel surface, window server and apps.

Switzach is documented as a separate jailbroken-like iOS environment with its own SpringBoard, installed as a ROM for Nyxian. Therefore, a working Sileo session in that setup is not evidence that an ordinary app can directly host the stock jailbreak Sileo backend. The important architectural lesson is that Sileo is running against a guest package/system environment supplied by the ROM/runtime, rather than modifying the host iOS installation.

The current public documentation describes these components at a high level. The exact 0.12.0 source/tag still needs to be pinned and compared before making version-specific claims.

## URX Core current position

URX Core already has:
- SwiftUI host app and app-container workspace.
- A package metadata parser and Debian archive inspection.
- An APT Packages index parser and dependency planner.
- A prototype root-URL repository manager.
- A manifest-based extension runtime and app-local respring.

It does not yet have:
- A complete guest OS/process runtime comparable to Nyxian.
- A complete APT acquisition stack (all compression formats, Release metadata model, signature trust).
- A dpkg-compatible database and transaction engine.
- A compatible execution environment for package maintainer scripts or native tweak code.
- Sileo's UI/backend dependencies integrated into the app.

## Proposed integration architecture

Keep the host iOS app and guest environment clearly separated:

1. URX Guest Root — app-container-owned filesystem layout, package database and configuration.
2. APT compatibility service — repository source semantics, Release parsing, index acquisition/decompression, hash verification and trust state.
3. Package database / resolver — installed-state model, architecture policy, version selection, dependency planning and transaction preview.
4. Sileo adapter — a narrow bridge exposing repository, package, download and transaction state to a compatible Sileo UI layer.
5. URX UI host — launch and manage the package manager inside the URX environment; keep the existing SwiftUI shell available.

The first integration milestone should be a Sileo-compatible source and package catalogue, not executing arbitrary jailbreak package scripts. Native tweak execution and host-system modification are outside the safe app-contained scope. Any later extension execution must use an explicit URX-owned API and remain confined to URX's own data/runtime.

## Next engineering milestones

1. Correct flat APT source handling to match Sileo's ./ model, including root Release, Release.gpg, and the full index compression preference list.
2. Add proper Release parsing, architecture/component selection, index hash verification and explicit trust status. Do not silently treat unsigned metadata as trusted.
3. Extend package records with repository provenance, multiple versions, Provides/virtual packages and pin/priority policy.
4. Define a stable adapter protocol between Sileo-facing UI and URX's package services.
5. Prototype a minimal UI integration after the backend contract is stable; assess the upstream UI's UIKit and dependency footprint before choosing source reuse versus a compatible reimplementation.

## Licensing

Sileo's repository declares BSD 4-Clause. If code is copied or adapted, preserve the required notices and comply with all license conditions. This audit does not copy upstream source code.
