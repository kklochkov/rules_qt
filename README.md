# Qt5/Qt6 rules for [Bazel](https://bazel.build)

The set of rules to build GUI applications with [Qt Framework](https://qt.io).

Requires **Bazel 8+** (tested with 8.7.0). Windows is not supported.

## Qt modules

Rules should support all available pre-installed Qt modules. [qt_local_repo](#list-of-repository-rules) (a repository rule) queries `qmake` to get full info
about available Qt tools, libraries, plugins and QtQuick imports.
So, all modules should be supported (if installed). Though, I tested mostly QtWidget, QtQuick/QtQml and QtQuick3D.

## Qt tools

- [moc](https://doc.qt.io/qt-6/moc.html) ([Qt5](https://doc.qt.io/qt-5/moc.html)) -- [qt_cc_moc](#list-of-rules) and [qt_cc_moc_import](#list-of-rules)
- [rcc](https://doc.qt.io/qt-6/rcc.html) ([Qt5](https://doc.qt.io/qt-5/rcc.html)) -- [qt_cc_rcc](#list-of-rules) and [qt_qrc](#list-of-rules)
- [uic](https://doc.qt.io/qt-6/uic.html) ([Qt5](https://doc.qt.io/qt-5/uic.html)) -- [qt_cc_uic](#list-of-rules)
- [QtQuick/QtQml](https://www.qt.io/blog/qml-type-registration-in-qt-5.15) -- [qt_qml_cc_module](#list-of-rules) and [qt_qml_import](#list-of-macros)
- [balsam](https://doc.qt.io/qt-6/qtquick3d-tool-balsam.html) ([Qt5](https://doc.qt.io/qt-5/qtquick3d-tool-balsam.html)) -- [qt_balsam](#list-of-rules)

## Rules and macros

Besides the aforementioned set of rules, there are two convenience macros available: [qt_cc_library](#list-of-macros) and [qt_cc_binary](#list-of-macros).

Rules are intended to be used when one needs more fine-grained Qt target composition.

Macros, usually, are the first choice to build Qt targets, because of their simplicity of use.
In essence they still use the same Qt rules, but nicely hide implementation details from a user.

For QML type registration, rules use a scoped Qt built-in metatype selection for
`qmltyperegistrar` foreign types. This avoids feeding unrelated SDK-wide metatypes
that can cause duplicate C++ type warnings. The resolver logic lives in
`qt/private/qml_metatypes.bzl`.

`qt_cc_binary` and `qt_cc_library` automatically forward their Qt deps to
`qt_qml_cc_module` (when `qml_module_name` is used), so scoped metatypes are
derived without additional user wiring.

## Supported platforms

Tested on Ubuntu (24.04) and macOS (Apple Silicon). Windows is not supported.

## What is not supported

- deployment is not supported
- dynamic plugins development is not supported
- since rules rely on pre-installed Qt on a host, produced binaries are not hermetic

## Before using rules

In order to use rules, Qt needs to be installed on a host and the path to `qmake` needs to be provided in [qt_local_repo](#list-of-repository-rules)'s `path` attribute (or `paths` for multi-platform setups).

Qt can be installed in several ways:
- via `brew` (macOS)
- via `apt` (Ubuntu/Debian)
- via official [Qt Installer](https://doc.qt.io/qt-5/gettingstarted.html)
- build from source using [qt_http_repo](#list-of-repository-rules) chained with [qt_remote_repo](#list-of-repository-rules) via the `qt.remote_repo()` extension

### Building from source prerequisites

When using `qt.remote_repo` to build Qt from source, the following host packages
are required on Ubuntu/Debian:

```bash
# Build tools
sudo apt install build-essential
# Qt6 additionally requires:
sudo apt install cmake ninja-build

# Font rendering
sudo apt install libfontconfig-dev libfreetype-dev libharfbuzz-dev

# Image formats
sudo apt install libpng-dev libjpeg-dev

# OpenGL / EGL
sudo apt install libgl-dev libegl-dev libglu1-mesa-dev

# xcb platform plugin (required for GUI applications and tools like balsam)
sudo apt install libx11-xcb-dev libxcb1-dev libxcb-cursor-dev libxcb-glx0-dev \
  libxcb-icccm4-dev libxcb-image0-dev libxcb-keysyms1-dev libxcb-randr0-dev \
  libxcb-render0-dev libxcb-render-util0-dev libxcb-shape0-dev libxcb-shm0-dev \
  libxcb-sync-dev libxcb-util-dev libxcb-xfixes0-dev libxcb-xinerama0-dev \
  libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev
```

### Ubuntu/Debian (apt)

**Qt5:**
```bash
sudo apt install qtbase5-dev qt5-qmake qtdeclarative5-dev qtquickcontrols2-5-dev
# QML runtime modules (required for running QML applications):
sudo apt install qml-module-qtquick2 qml-module-qtquick-controls2 \
  qml-module-qtquick-templates2 qml-module-qtquick-window2
```

**Qt6:**
```bash
sudo apt install qt6-base-dev qmake6 qt6-declarative-dev
# For QtQuick3D:
sudo apt install qt6-quick3d-dev qt6-shadertools-dev
# QML runtime modules (required for running QML applications):
sudo apt install qml6-module-qtquick qml6-module-qtquick-controls \
  qml6-module-qtquick-templates qml6-module-qtquick-window \
  qml6-module-qtquick-layouts
```

> **Note:** Qt5 Quick3D is not available as an apt package. Use `qt.remote_repo` (source build) or Homebrew on macOS for Qt5 Quick3D support.

Use the following paths in `qt.local_repo`:
- Qt5: `path = "/usr/lib/x86_64-linux-gnu/qt5"`
- Qt6: `path = "/usr/lib/qt6"`

### macOS (Homebrew)

```bash
brew install qt@5   # or: brew install qt  (for Qt6)
```

Use the following paths in `qt.local_repo`:
- Qt5: `path = "/opt/homebrew/opt/qt@5"`
- Qt6: `path = "/opt/homebrew/opt/qt"`

## Installation

### `MODULE.bazel` file

```starlark
module(name = "my_project")

bazel_dep(name = "rules_qt", version = "2.0.0")
# rules_qt is not published to the Bazel Central Registry.
# Use git_override or local_path_override to depend on it:
# git_override(
#     module_name = "rules_qt",
#     remote = "https://github.com/kklochkov/rules_qt",
#     commit = "<commit_sha>",
# )

qt = use_extension("@rules_qt//qt:extensions.bzl", "qt")

qt.remote_repo(
    name = "qt5_remote",
    base_url = "https://download.qt.io/archive/qt/5.15/5.15.18/submodules",
    configure_args = [...],
    # @unsorted-dict-items
    # order matters
    modules = {...},
    prefix = "qt-5.15.18",
)
# See examples/MODULE.bazel for complete configure_args and modules values.

qt.local_repo(
    name = "qt6_local",
    # Single-platform shorthand:
    # path = "/opt/homebrew/opt/qt",
    # Multi-platform:
    paths = {
        "macos-arm64": "/opt/homebrew/opt/qt",
        "linux-x86_64": "/usr/lib/qt6",
    },
)

qt.active_sdk(
    name = "qt",
    repo = "qt5_remote",  # or "qt6_local"
)

use_repo(qt, "qt")

# optional: add Qt5 local and switch active SDK
# qt.local_repo(
#     name = "qt5_local",
#     paths = {
#         "macos-arm64": "/opt/homebrew/opt/qt@5",
#         "linux-x86_64": "/usr/lib/x86_64-linux-gnu/qt5",
#     },
# )
# qt.active_sdk(name = "qt", repo = "qt5_local")

register_toolchains(
    "@qt//:qt_linux_x86_64_toolchain",
    "@qt//:qt_linux_arm64_toolchain",
    "@qt//:qt_osx_arm64_toolchain",
)
```

**Path examples:**

- Homebrew Qt6 (macOS): `/opt/homebrew/opt/qt`
- Homebrew Qt5 (macOS): `/opt/homebrew/opt/qt@5`
- Ubuntu Qt6: `/usr/lib/qt6`
- Ubuntu Qt5: `/usr/lib/x86_64-linux-gnu/qt5`

Declare local and remote candidates with `qt.local_repo(...)` and `qt.remote_repo(...)`.
Select exactly one candidate with `qt.active_sdk(name = "qt", repo = ...)`.
Expose the active Qt as `@qt` via `use_repo(qt, "qt")` and register toolchains from `@qt`.

For [qt_cc_binary](doc/docs.md#qt_cc_binary), if your runtime cannot locate QML imports/plugins automatically,
set `qt_qml_path` and `qt_plugin_path` (or equivalent env vars) explicitly.

### `BUILD` file

```starlark
load("@rules_qt//qt:defs.bzl", "qt_cc_binary")

qt_cc_binary(
    name = "hello_world",
    srcs = ["main.cpp"],
    deps = ["@qt//:QtCore"],
)
```

See [examples](#examples) section on how to run examples.

## Examples

To run examples, `cd examples` and follow instructions in [README.md](examples/README.md).

The examples repository includes additional external repos for patched Qt Declarative/QtQuick3D sources and sample assets,
declared in `examples/MODULE.bazel`.

## List of repository rules
* [qt_local_repo](doc/qt_local_repo-docs.md)
* [qt_http_repo](doc/qt_http_repo-docs.md)
* [qt_remote_repo](doc/qt_remote_repo-docs.md)

## List of rules
* [qt_cc_moc](doc/docs.md#qt_cc_moc)
* [qt_cc_moc_import](doc/docs.md#qt_cc_moc_import)
* [qt_qrc](doc/docs.md#qt_qrc)
* [qt_cc_rcc](doc/docs.md#qt_cc_rcc)
* [qt_cc_uic](doc/docs.md#qt_cc_uic)
* [qt_qml_cc_module](doc/docs.md#qt_qml_cc_module)
* [qt_balsam](doc/docs.md#qt_balsam)

## List of macros
* [qt_cc_library](doc/docs.md#qt_cc_library)
* [qt_cc_binary](doc/docs.md#qt_cc_binary)
* [qt_qml_import](doc/docs.md#qt_qml_import)

## Providers
* [MocInfo](doc/providers-docs.md#MocInfo)
* [QrcInfo](doc/providers-docs.md#QrcInfo)

## Toolchain
* [QtInfo](doc/toolchain-docs.md#QtInfo)
* [QtConfInfo](doc/toolchain-docs.md#QtConfInfo)
* [qt_toolchain](doc/toolchain-docs.md#qt_toolchain)

## Dependencies

* [Skylib](https://github.com/bazelbuild/bazel-skylib)
* [Stardoc](https://github.com/bazelbuild/stardoc)
* [rules_cc](https://github.com/bazelbuild/rules_cc)
* [platforms](https://github.com/bazelbuild/platforms)
