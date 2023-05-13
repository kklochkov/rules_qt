<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Repository rule that fetches, configures and builds Qt and makes it available in Bazel.

<a id="qt_http_repo"></a>

## qt_http_repo

<pre>
qt_http_repo(<a href="#qt_http_repo-name">name</a>, <a href="#qt_http_repo-base_url">base_url</a>, <a href="#qt_http_repo-configure_args">configure_args</a>, <a href="#qt_http_repo-modules">modules</a>, <a href="#qt_http_repo-prefix">prefix</a>, <a href="#qt_http_repo-repo_mapping">repo_mapping</a>)
</pre>


The rule downloads Qt's modules from http://download.qt.io/archive/qt/,
extracts, configures and builds them.

The configuration and building are done as per [Building Qt5 from git](https://wiki.qt.io/Building_Qt_5_from_Git)
and [Building Qt6 from git](https://wiki.qt.io/Building_Qt_6_from_Git), that means that all requirements and tools
need to be installed on a host.

The build is not hermetic, because it uses host tools.

The rule is supposed to be used in conjunction with [qt_local_repo](qt_local_repo-docs.md).

**Example**

In `WORKSPACE`
```
# Qt remote repo
load("@com_github_kklochkov_rules_qt//qt:qt_http_repo.bzl", "qt_http_repo")

qt_http_repo(
    name = "qt_5.15.8",
    base_url = "https://download.qt.io/official_releases/qt/5.15/5.15.8/submodules",
    configure_args = [...],
    # @unsorted-dict-items
    # order matters
    modules = {...},
    prefix = "qt-5.15.8",
)

# Qt local repo
load("@com_github_kklochkov_rules_qt//qt:qt_local_repo.bzl", "qt_local_repo")

qt_local_repo(
    name = "qt",
    qt_http_repo = "@qt_5.15.8",
)
```

See [examples/WORKSPACE](../examples/WORKSPACE) for a complete example.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="qt_http_repo-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="qt_http_repo-base_url"></a>base_url |  A base url to Qt's archives repo.   | String | required |  |
| <a id="qt_http_repo-configure_args"></a>configure_args |  Qt's configure args. <code>-prefix</code>, <code>-R</code> and <code>-rpath</code> should not be provided, because they are handled internally by the rules.   | List of strings | required |  |
| <a id="qt_http_repo-modules"></a>modules |  A list of Qt's modules to be built. The rules doesn't attempt to resolve dependencies in which modules have to be built, except QtBase which always gets built first. That means that a user of the rule, must provide correct modules order for the build to succeed. It is recommend to use <code>@unsorted-dict-items</code> to prevent sorting of values in this field upon declaration.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | required |  |
| <a id="qt_http_repo-prefix"></a>prefix |  A prefix where Qt will be installed.   | String | required |  |
| <a id="qt_http_repo-repo_mapping"></a>repo_mapping |  A dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.&lt;p&gt;For example, an entry <code>"@foo": "@bar"</code> declares that, for any time this repository depends on <code>@foo</code> (such as a dependency on <code>@foo//some:target</code>, it should actually resolve that dependency within globally-declared <code>@bar</code> (<code>@bar//some:target</code>).   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | required |  |


