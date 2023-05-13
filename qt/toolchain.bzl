"""Qt toolchain that allows building Qt/QtQuick applications with Bazel."""

load("@bazel_skylib//lib:paths.bzl", "paths")

QtInfo = provider(
    fields = {
        "balsam": "The path to Qt's `balsam` tool. See [qt_balsam](docs.md#qt_balsam).",
        "headers": "The list of Qt's headers.",
        "metatypes": "The list of Qt's metatypes.",
        "moc": "The path to Qt's `moc` tool. See [qt_cc_moc](docs.md#qt_cc_moc).",
        "qmltyperegistrar": "The path to Qt's `qmltyperegistrar` tool. See [qt_qml_cc_module](docs.md#qt_qml_cc_module).",
        "rcc": "The path to Qt's `rcc` tool. See [qt_cc_rcc](docs.md#qt_cc_rcc).",
        "uic": "The path to Qt's `uic` tool. See [qt_cc_uic](docs.md#qt_cc_uic).",
    },
)

def _qt_toolchain_impl(ctx):
    toolchain_package = paths.dirname(ctx.build_file_path)
    toolchain_info = platform_common.ToolchainInfo(
        qtinfo = QtInfo(
            balsam = ctx.executable.balsam,
            moc = ctx.executable.moc,
            qmltyperegistrar = ctx.executable.qmltyperegistrar,
            rcc = ctx.executable.rcc,
            uic = ctx.executable.uic,
            metatypes = ctx.attr.metatypes,
            headers = ctx.attr.headers,
        ),
    )
    return [toolchain_info]

qt_toolchain = rule(
    implementation = _qt_toolchain_impl,
    doc = """
Implements Qt's toolchain to build Qt and QtQuick applications with Bazel.

Qt support: Qt5 and Qt6.

Testing: Qt 5.15 and Qt 6.4.

Platforms: linux and macOS.
""",
    attrs = {
        "balsam": attr.label(
            mandatory = True,
            executable = True,
            cfg = "exec",
            allow_single_file = True,
            doc = "The path to Qt's `balsam` tool. See [qt_balsam](docs.md#qt_balsam).",
        ),
        "headers": attr.label(
            allow_files = True,
            mandatory = True,
            doc = "The list of Qt's headers.",
        ),
        "metatypes": attr.label(
            mandatory = True,
            allow_files = False,
            doc = "The list of Qt's metatypes.",
        ),
        "moc": attr.label(
            mandatory = True,
            executable = True,
            cfg = "exec",
            allow_single_file = True,
            doc = "The path to Qt's `moc` tool. See [qt_cc_moc](docs.md#qt_cc_moc).",
        ),
        "qmltyperegistrar": attr.label(
            mandatory = True,
            executable = True,
            cfg = "exec",
            allow_single_file = True,
            doc = "The path to Qt's `qmltyperegistrar` tool. See [qt_qml_cc_module](docs.md#qt_qml_cc_module).",
        ),
        "rcc": attr.label(
            mandatory = True,
            executable = True,
            cfg = "exec",
            allow_single_file = True,
            doc = "The path to Qt's `rcc` tool. See [qt_cc_rcc](docs.md#qt_cc_rcc).",
        ),
        "uic": attr.label(
            mandatory = True,
            executable = True,
            cfg = "exec",
            allow_single_file = True,
            doc = "The path to Qt's `uic` tool. See [qt_cc_uic](docs.md#qt_cc_uic).",
        ),
    },
)
