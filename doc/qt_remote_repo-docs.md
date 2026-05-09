<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Repository rule to make source-built Qt available in Bazel.

<a id="qt_remote_repo"></a>

## qt_remote_repo

<pre>
load("@rules_qt//qt:qt_remote_repo.bzl", "qt_remote_repo")

qt_remote_repo(<a href="#qt_remote_repo-name">name</a>, <a href="#qt_remote_repo-qt_http_repo">qt_http_repo</a>, <a href="#qt_remote_repo-repo_mapping">repo_mapping</a>)
</pre>

Repository rule that allows the use of source-built Qt to be used with Bazel.

This rule consumes the output of [qt_http_repo](qt_http_repo-docs.md), reads
its installation prefix and re-exports discovered tools, libraries and headers
for Bazel targets and toolchains.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="qt_remote_repo-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="qt_remote_repo-qt_http_repo"></a>qt_http_repo |  The [qt_http_repo](qt_http_repo-docs.md) target name used to bootstrap Qt.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="qt_remote_repo-repo_mapping"></a>repo_mapping |  In `WORKSPACE` context only: a dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.<br><br>For example, an entry `"@foo": "@bar"` declares that, for any time this repository depends on `@foo` (such as a dependency on `@foo//some:target`, it should actually resolve that dependency within globally-declared `@bar` (`@bar//some:target`).<br><br>This attribute is _not_ supported in `MODULE.bazel` context (when invoking a repository rule inside a module extension's implementation function).   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  |


