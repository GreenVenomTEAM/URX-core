# Sileo integration

URX Core embeds the upstream Sileo source as an in-process UIKit framework.

- Upstream repository: https://github.com/Sileo/Sileo
- Pinned source commit: c9f70158a037dc76b91c450e72af2de0514dd3ee
- Upstream license: BSD 4-Clause; retain the upstream license and notices.
- The upstream `SileoAppDelegate` is excluded because URX owns the application lifecycle.
- The upstream source is compiled with `TARGET_SANDBOX`; this is not a jailbreak runtime.
- The original storyboard and resources are hosted in the URX app bundle.
- The sandbox UI and package backend are being adapted in separate steps.

Important: the upstream sandbox demo has a no-op package-operation path. Do not treat its completion callback as a successful install. Before exposing package install/remove actions, replace that path with an explicit URX sandbox backend that only handles supported data-only package payloads and never runs maintainer scripts or host-system commands.
