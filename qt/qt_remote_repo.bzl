"""Repository rule to make source-built Qt available in Bazel."""

load(":private/utils.bzl", "QT_REPO_INSTALL_FILE")
load(":qt_local_repo.bzl", "materialize_qt_repo")

def _qt_remote_repo_impl(repository_ctx):
    """Repository rule's implementation function."""
    qt_dir_path = repository_ctx.path(repository_ctx.attr.qt_http_repo.relative(QT_REPO_INSTALL_FILE))
    qt_dir = repository_ctx.read(qt_dir_path).splitlines()[0]
    materialize_qt_repo(repository_ctx, qt_dir)

qt_remote_repo = repository_rule(
    implementation = _qt_remote_repo_impl,
    doc = """
Repository rule that allows the use of source-built Qt to be used with Bazel.

This rule consumes the output of [qt_http_repo](qt_http_repo-docs.md), reads
its installation prefix and re-exports discovered tools, libraries and headers
for Bazel targets and toolchains.
""",
    attrs = {
        "qt_http_repo": attr.label(mandatory = True, allow_single_file = True, doc = """
The [qt_http_repo](qt_http_repo-docs.md) target name used to bootstrap Qt.
"""),
        "_qt_toolchain_bzl": attr.label(default = Label("@rules_qt//qt:toolchain.bzl")),
        "_qt_toolchain_type": attr.label(default = Label("@rules_qt//qt:toolchain_type")),
        "_required_tools": attr.string_list(default = ["moc", "rcc", "uic", "qmltyperegistrar", "balsam"]),
    },
    local = True,
)
