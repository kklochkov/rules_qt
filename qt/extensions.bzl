"""Bzlmod module extension for configuring Qt repositories.

Provides three tag classes for use in `MODULE.bazel`:

- `qt.local_repo(...)` — declares a locally installed Qt SDK candidate.
- `qt.remote_repo(...)` — declares a source-built Qt SDK candidate (downloaded and compiled from source).
- `qt.active_sdk(...)` — selects which candidate to activate as the Qt toolchain.

Exactly one `active_sdk` must be declared. Its `repo` attribute must match the `name` of
a `local_repo` or `remote_repo` declaration.

**Example**

```starlark
qt = use_extension("@rules_qt//qt:extensions.bzl", "qt")

qt.local_repo(
    name = "qt6_local",
    paths = {
        "macos-arm64": "/opt/homebrew/opt/qt",
        "linux-x86_64": "/usr/lib/qt6",
    },
)

qt.remote_repo(
    name = "qt5_remote",
    base_url = "https://download.qt.io/archive/qt/5.15/5.15.18/submodules",
    configure_args = ["-release", "-opensource", "-confirm-license", "-nomake", "tests"],
    modules = {"qtbase-everywhere-opensource-src-5.15.18": "..."},
    prefix = "qt-5.15.18",
)

qt.active_sdk(name = "qt", repo = "qt6_local")

use_repo(qt, "qt")
register_toolchains("@qt//:qt_linux_x86_64_toolchain")
```

See `examples/MODULE.bazel` for a complete working example.
"""

load(":qt_http_repo.bzl", "qt_http_repo")
load(":qt_local_repo.bzl", "qt_local_repo")
load(":qt_remote_repo.bzl", "qt_remote_repo")

def _find_root_module(module_ctx):
    for mod in module_ctx.modules:
        if mod.is_root:
            return mod
    fail("rules_qt: unable to locate root module")

def _collect_candidates(candidates, kind):
    result = {}
    for candidate in candidates:
        if candidate.name in result:
            fail("rules_qt: duplicate {kind} candidate '{name}'".format(kind = kind, name = candidate.name))
        result[candidate.name] = candidate
    return result

def _qt_extension_impl(module_ctx):
    """Resolves the active Qt SDK from declared local/remote candidates and materializes the repository."""
    mod = _find_root_module(module_ctx)

    if len(mod.tags.active_sdk) == 0:
        # buildifier: disable=print
        print("rules_qt: no qt.active_sdk() declared; Qt toolchain will not be available")
        return

    if len(mod.tags.active_sdk) != 1:
        fail("rules_qt: exactly one qt.active_sdk(...) must be declared")

    local_candidates = _collect_candidates(mod.tags.local_repo, "local_repo")
    remote_candidates = _collect_candidates(mod.tags.remote_repo, "remote_repo")
    active = mod.tags.active_sdk[0]

    if active.repo in local_candidates and active.repo in remote_candidates:
        fail("rules_qt: active_sdk.repo '{name}' is ambiguous between local and remote candidates".format(name = active.repo))

    if active.repo in local_candidates:
        candidate = local_candidates[active.repo]
        kwargs = {"name": active.name}
        if candidate.path:
            kwargs["path"] = candidate.path
        if candidate.paths:
            kwargs["paths"] = candidate.paths
        qt_local_repo(**kwargs)
        return

    if active.repo in remote_candidates:
        candidate = remote_candidates[active.repo]
        qt_http_name = "qt_http_repo_{name}".format(name = active.repo)
        qt_http_repo(
            name = qt_http_name,
            base_url = candidate.base_url,
            configure_args = candidate.configure_args,
            modules = candidate.modules,
            prefix = candidate.prefix,
            timeout = candidate.timeout,
        )
        qt_remote_repo(
            name = active.name,
            qt_http_repo = "@{name}".format(name = qt_http_name),
        )
        return

    fail("rules_qt: active_sdk.repo '{name}' not found among local_repo/remote_repo declarations".format(name = active.repo))

qt = module_extension(
    doc = """Configures a Qt toolchain from locally installed or source-built Qt SDKs.

Declare one or more `local_repo` and/or `remote_repo` candidates, then select
the active one with `active_sdk`. Only the active candidate is materialized.""",
    implementation = _qt_extension_impl,
    tag_classes = {
        "local_repo": tag_class(
            doc = """Declares a locally installed Qt SDK candidate.

Specify either `path` (single platform) or `paths` (multi-platform dict keyed by
`<os>-<arch>`, e.g. `linux-x86_64`, `macos-arm64`). The candidate is only
materialized if selected by `active_sdk`.""",
            attrs = {
                "name": attr.string(
                    mandatory = True,
                    doc = "Unique name for this candidate. Referenced by `active_sdk.repo`.",
                ),
                "path": attr.string(
                    doc = "Absolute path to the Qt installation directory (single-platform shorthand).",
                ),
                "paths": attr.string_dict(
                    doc = "Platform-keyed dict of absolute paths (`{\"linux-x86_64\": \"/usr/lib/qt6\", \"macos-arm64\": \"/opt/homebrew/opt/qt\"}`).",
                ),
            },
        ),
        "remote_repo": tag_class(
            doc = """Declares a source-built Qt SDK candidate.

Qt modules are downloaded from `base_url`, configured, compiled, and installed
into the Bazel external cache. The build uses host tools and is not hermetic.
The candidate is only materialized if selected by `active_sdk`.""",
            attrs = {
                "name": attr.string(
                    mandatory = True,
                    doc = "Unique name for this candidate. Referenced by `active_sdk.repo`.",
                ),
                "base_url": attr.string(
                    mandatory = True,
                    doc = "Base URL for downloading Qt source archives (e.g. `https://download.qt.io/archive/qt/5.15/5.15.18/submodules`).",
                ),
                "configure_args": attr.string_list(
                    mandatory = True,
                    doc = "Arguments passed to Qt's `configure` script (e.g. `[\"-release\", \"-opensource\", \"-confirm-license\"]`).",
                ),
                "modules": attr.string_dict(
                    mandatory = True,
                    doc = "Ordered dict of `{archive_name: sha256}`. The first entry must be `qtbase`. Order matters for build dependencies.",
                ),
                "prefix": attr.string(
                    mandatory = True,
                    doc = "Installation prefix directory name (e.g. `qt-5.15.18`).",
                ),
                "timeout": attr.int(
                    default = 2400,
                    doc = "Build timeout in seconds for each module. Default: 2400 (40 minutes).",
                ),
            },
        ),
        "active_sdk": tag_class(
            doc = """Selects which Qt SDK candidate to activate as the toolchain.

Exactly one `active_sdk` must be declared per module. Its `repo` must match
the `name` of a previously declared `local_repo` or `remote_repo`.""",
            attrs = {
                "name": attr.string(
                    mandatory = True,
                    doc = "Name of the repository to create (typically `\"qt\"`).",
                ),
                "repo": attr.string(
                    mandatory = True,
                    doc = "Name of the `local_repo` or `remote_repo` candidate to activate.",
                ),
            },
        ),
    },
)
