<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Repository rule to make locally installed Qt available in Bazel.

<a id="qt_local_repo"></a>

## qt_local_repo

<pre>
qt_local_repo(<a href="#qt_local_repo-name">name</a>, <a href="#qt_local_repo-path">path</a>, <a href="#qt_local_repo-qt_http_repo">qt_http_repo</a>, <a href="#qt_local_repo-repo_mapping">repo_mapping</a>)
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

**linux:** `WORKSPACE`
```
load("@com_github_kklochkov_rules_qt//qt:qt_local_repo.bzl", "qt_local_repo")

# linux
qt_local_repo(
    name = "qt",
    path = "/usr/lib/qt6",
)
```

**macOS:** `WORKSPACE`
```
load("@com_github_kklochkov_rules_qt//qt:qt_local_repo.bzl", "qt_local_repo")

qt_local_repo(
    name = "qt",
    path = "/opt/homebrew/opt/qt5",
)
```

**qtconf.bzl**
`BUILD`
```
load("@qt//:qtconf.bzl", "QT_VERSION")
```


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="qt_local_repo-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="qt_local_repo-path"></a>path |  The path to locally installed Qt's folder where <code>qmake</code> is located, usually it is <code>bin</code> folder.   | String | optional | <code>""</code> |
| <a id="qt_local_repo-qt_http_repo"></a>qt_http_repo |  The [qt_http_repo](qt_http_repo-docs.md) target name to boostrap Qt.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="qt_local_repo-repo_mapping"></a>repo_mapping |  A dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.&lt;p&gt;For example, an entry <code>"@foo": "@bar"</code> declares that, for any time this repository depends on <code>@foo</code> (such as a dependency on <code>@foo//some:target</code>, it should actually resolve that dependency within globally-declared <code>@bar</code> (<code>@bar//some:target</code>).   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | required |  |


