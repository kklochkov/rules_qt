<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Repository rule that fetches, configures and builds Qt and makes it available in Bazel.

<a id="qt_http_repo"></a>

## qt_http_repo

<pre>
load("@rules_qt//qt:qt_http_repo.bzl", "qt_http_repo")

qt_http_repo(<a href="#qt_http_repo-name">name</a>, <a href="#qt_http_repo-base_url">base_url</a>, <a href="#qt_http_repo-configure_args">configure_args</a>, <a href="#qt_http_repo-modules">modules</a>, <a href="#qt_http_repo-prefix">prefix</a>, <a href="#qt_http_repo-repo_mapping">repo_mapping</a>, <a href="#qt_http_repo-timeout">timeout</a>)
</pre>

The rule downloads Qt's modules from http://download.qt.io/archive/qt/,
extracts, configures and builds them.

The configuration and building are done as per [Building Qt5 from git](https://wiki.qt.io/Building_Qt_5_from_Git)
and [Building Qt6 from git](https://wiki.qt.io/Building_Qt_6_from_Git), that means that all requirements and tools
need to be installed on a host.

The build is not hermetic, because it uses host tools.

The rule is consumed by [qt_remote_repo](qt_remote_repo-docs.md) through the bzlmod
extension flow (`qt.remote_repo(...)` + `qt.active_sdk(...)`).

**Example**

In `MODULE.bazel`
```
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

qt.active_sdk(name = "qt", repo = "qt5_remote")

use_repo(qt, "qt")
```

See [examples/MODULE.bazel](../examples/MODULE.bazel) for a complete example.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="qt_http_repo-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="qt_http_repo-base_url"></a>base_url |  A base url to Qt's archives repo.   | String | required |  |
| <a id="qt_http_repo-configure_args"></a>configure_args |  Qt's configure args. `-prefix`, `-R` and `-rpath` should not be provided, because they are handled internally by the rules.   | List of strings | required |  |
| <a id="qt_http_repo-modules"></a>modules |  A list of Qt's modules to be built. The rules doesn't attempt to resolve dependencies in which modules have to be built, except QtBase which always gets built first. That means that a user of the rule, must provide correct modules order for the build to succeed. It is recommend to use `@unsorted-dict-items` to prevent sorting of values in this field upon declaration.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | required |  |
| <a id="qt_http_repo-prefix"></a>prefix |  A prefix where Qt will be installed.   | String | required |  |
| <a id="qt_http_repo-repo_mapping"></a>repo_mapping |  In `WORKSPACE` context only: a dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.<br><br>For example, an entry `"@foo": "@bar"` declares that, for any time this repository depends on `@foo` (such as a dependency on `@foo//some:target`, it should actually resolve that dependency within globally-declared `@bar` (`@bar//some:target`).<br><br>This attribute is _not_ supported in `MODULE.bazel` context (when invoking a repository rule inside a module extension's implementation function).   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  |
| <a id="qt_http_repo-timeout"></a>timeout |  Build timeout in seconds for each Qt module. Increase for large modules on slow machines.   | Integer | optional |  `2400`  |


