# Sileo integration

URX Core compiles the pinned upstream Sileo sources directly into the URXCore application target.

- Upstream repository: https://github.com/Sileo/Sileo
- Pinned source commit: c9f70158a037dc76b91c450e72af2de0514dd3ee
- Upstream license: BSD 4-Clause; retain the upstream license and notices.
- The upstream `SileoAppDelegate` is excluded because URX owns the application lifecycle.
- Sileo Swift, Objective-C, and C sources are compiled in the app target, avoiding a separate framework/module.
- The upstream bridging header is included through `Sources/URXBridging.h`; it provides declarations used by the original UI sources.
- The target defines `TARGET_SANDBOX` for both Swift and C/Objective-C compilation. This is not a jailbreak runtime.
- The original storyboard and resources are hosted in the URX app bundle.

Important: Sileo's sandbox compilation path intentionally does not perform APT package operations. Its completion callback must not be presented as a successful install. Before exposing package install/remove actions, implement a separate URX sandbox backend limited to validated data-only payloads; do not run maintainer scripts or host-system commands.
