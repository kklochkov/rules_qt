# Qt5/Qt6 rules for [Bazel](https://bazel.build)

The set of rules to build GUI applications with [Qt Framework](https://qt.io).
I created these rules when [QtQuick3D](https://doc.qt.io/qt-5/qtquick3d-index.html) was introduced to experiment with it.
I finally found time to clean up rules and make them public, so others that both love Bazel and Qt can use them.

## Qt modules

Rules should support all available pre-installed Qt modules. [qt_local_repo](#list-of-repository-rules) (a repository rule) queries `qmake` to get full info
about available Qt tools, libraries, plugins and QtQuick imports.
So, all modules should be supported (if installed). Though, I tested mostly QtWidget, QtQuick/QtQml and QtQuick3D.

## Qt tools

- [moc](https://doc.qt.io/qt-5/moc.html) -- [qt_cc_moc](#list-of-rules) and [qt_cc_moc_import](#list-of-rules)
- [rcc](https://doc.qt.io/qt-5/rcc.html) -- [qt_cc_rcc](#list-of-rules) and [qt_qrc](#list-of-rules)
- [uic](https://doc.qt.io/qt-5/uic.html) -- [qt_cc_uic](#list-of-rules)
- [QtQuick/QtQml](https://www.qt.io/blog/qml-type-registration-in-qt-5.15) -- [qt_qml_cc_module](#list-of-rules) and [qt_qml_import](#list-of-macros)
- [balsam](https://doc.qt.io/qt-5/qtquick3d-tool-balsam.html) -- [qt_balsam](#list-of-rules)

## Rules and macros

Besides the aforementioned set of rules, there are two convenience macros available: [qt_cc_library](#list-of-macros) and [qt_cc_binary](#list-of-macros).

Rules are intended to be used when one needs more fine-grained Qt target composition.

Macros, usually, are the first choice to build Qt targets, because of their simplicity of use.
In essence they still use the same Qt rules, but nicely hide implementation details from a user.

## Supported platforms

Tested on Ubuntu (22.04) and macOS Ventura 13.3.1 (Apple Silicon).

## What is not supported

- deployment is not supported
- dynamic plugins development is not supported
- since rules rely on pre-installed Qt on a host, produces binaries are not hermetic

## Before using rules

In order to use rules, Qt needs to be installed on a host and the path to `qmake` needs to be provided in [qt_local_repo](#list-of-repository-rules)'s `path` attribute.

See `examples/WORKSPACE` for additional info.

Qt can be installed in several ways:
- via `brew` (macOS)
- via `apt` (Ubuntu)
- via official [Qt Installer](https://doc.qt.io/qt-5/gettingstarted.html)
- build from source using [qt_http_repo](#list-of-repository-rules) and chaining it with [qt_local_repo](#list-of-repository-rules)

## Installation

### `WORKSPACE` file

See `release` for the `WORKSPACE` setup of the currect release.

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "com_github_kklochkov_rules_qt",
    urls = ["<URL>"],
    sha256 = "<SHA256>",
)

load("@com_github_kklochkov_rules_qt//qt:repositories.bzl", "rules_qt_dependencies", "rules_qt_toolchains")

rules_qt_dependencies()

rules_qt_toolchains()

# Qt local repo
load("@com_github_kklochkov_rules_qt//qt:qt_local_repo.bzl", "qt_local_repo")

qt_local_repo(
    name = "qt",
    path = "/path/to/qt/bin",
)
```

**IMPORTANT NOTE:**

[qt_local_repo](doc/qt_local_repo-docs.md) should be named `qt`, because the repo is used to retrieve
installation paths from `qtconf.bzl` which are used by [qt_cc_binary](doc/docs.md#qt_cc_binary).

In case a different name is used for the repository, it will not be possible to use [qt_cc_binary](doc/docs.md#qt_cc_binary) without errors.
One will have to use `cc_binary` and manually provide `QT_PLUGIN_PATH`, `QML2_IMPORT_PATH` and `QML_IMPORT_PATH` from
`@<custom_qt_repo_nam>//:qtconf.bzl`. See the reference [usage](examples/hello_rules/4_qml/BUILD).

### `BUILD` file

```starlark
load("@com_github_kklochkov_rules_qt//qt:defs.bzl", "qt_cc_binary")

qt_cc_binary(
    name = "hello_world",
    srcs = ["main.cpp"],
    deps = ["@qt//:QtCore"],
)
```

See [examples](#examples) section on how to run examples.

## Examples

To run examples, `cd examples` and follow instructions in [README.md](examples/README.md).

## List of repository rules
* [qt_local_repo](doc/qt_local_repo-docs.md)
* [qt_http_repo](doc/qt_http_repo-docs.md)

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
* [qt_toolchain](doc/toolchain-docs.md#qt_toolchain)

## Dependencies

* [Skylib](https://github.com/bazelbuild/bazel-skylib)
* [Stardoc](https://github.com/bazelbuild/stardoc)
