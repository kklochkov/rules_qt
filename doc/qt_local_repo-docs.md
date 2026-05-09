<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Repository rule to make locally installed Qt available in Bazel.

<a id="materialize_qt_repo"></a>

## materialize_qt_repo

<pre>
load("@rules_qt//qt:qt_local_repo.bzl", "materialize_qt_repo")

materialize_qt_repo(<a href="#materialize_qt_repo-repository_ctx">repository_ctx</a>, <a href="#materialize_qt_repo-qt_dir">qt_dir</a>)
</pre>

Repository rule helper function that materializes a Qt SDK in Bazel format.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="materialize_qt_repo-repository_ctx"></a>repository_ctx |  <p align="center"> - </p>   |  none |
| <a id="materialize_qt_repo-qt_dir"></a>qt_dir |  <p align="center"> - </p>   |  none |


<a id="qt_local_repo"></a>

## qt_local_repo

<pre>
load("@rules_qt//qt:qt_local_repo.bzl", "qt_local_repo")

qt_local_repo(<a href="#qt_local_repo-name">name</a>, <a href="#qt_local_repo-path">path</a>, <a href="#qt_local_repo-paths">paths</a>, <a href="#qt_local_repo-repo_mapping">repo_mapping</a>)
</pre>

Repository rule that allows the use of locally installed Qt to be used with Bazel.

The rules invokes `qmake` which should exist in the provided `path` attribute,
collects information about Qt's installations paths and makes it accessible to other rules
by exporting `qtconf.bzl`. Creates symlinks to Qt's libraries, includes, plugins and QtQuick imports,
declares corresponding `cc_library`'es and populates toolchain with required tools for building Qt targets.

`qtconf.bzl` contains the same information as original Qt's conf (https://doc.qt.io/qt-5/qt-conf.html),
adjusted to be used in Bazel `BUILD` files.

## NOTE:

The repository rule autogenerates all discovered Qt's libraries and doesn't try to establish logical dependencies
between modules.
Therefore consumers of the repository will have to add Qt dependency targets manually to have a successful build.

## Example:

In `MODULE.bazel`
```
qt = use_extension("@rules_qt//qt:extensions.bzl", "qt")

# Single-platform (backward compatible):
qt.local_repo(
    name = "qt6_local",
    path = "/opt/homebrew/opt/qt",
)

# Multi-platform:
qt.local_repo(
    name = "qt6_local",
    paths = {
        "linux-x86_64": "/usr/lib/qt6",
        "macos-arm64": "/opt/homebrew/opt/qt",
    },
)

qt.active_sdk(name = "qt", repo = "qt6_local")
use_repo(qt, "qt")
```

Switch active local SDK by changing `qt.active_sdk(..., repo = ...)`.

**qtconf.bzl**
`BUILD`
```
load("@qt//:qtconf.bzl", "QT_VERSION")
```

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="qt_local_repo-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="qt_local_repo-path"></a>path |  The path to locally installed Qt's folder where `qmake` is located, usually it is `bin` folder. Use this for single-platform setups. For multi-platform, use `paths` instead.   | String | optional |  `""`  |
| <a id="qt_local_repo-paths"></a>paths |  Platform-keyed paths to locally installed Qt. Keys are `<os>-<arch>` strings, e.g. `{"linux-x86_64": "/usr/lib/qt6", "macos-arm64": "/opt/homebrew/opt/qt"}`. OS-only keys (e.g. `"linux"`) are also accepted as fallbacks. Exactly one of `path` or `paths` must be specified.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  `{}`  |
| <a id="qt_local_repo-repo_mapping"></a>repo_mapping |  In `WORKSPACE` context only: a dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.<br><br>For example, an entry `"@foo": "@bar"` declares that, for any time this repository depends on `@foo` (such as a dependency on `@foo//some:target`, it should actually resolve that dependency within globally-declared `@bar` (`@bar//some:target`).<br><br>This attribute is _not_ supported in `MODULE.bazel` context (when invoking a repository rule inside a module extension's implementation function).   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  |


