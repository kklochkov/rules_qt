"""Qt toolchain that allows building Qt/QtQuick applications with Bazel."""

QtInfo = provider(
    fields = {
        "balsam": "The path to Qt's `balsam` tool. See [qt_balsam](docs.md#qt_balsam).",
        "headers": "The list of Qt's headers.",
        "metatypes": "A dict mapping Qt module target names to their metatype File objects.",
        "moc": "The path to Qt's `moc` tool. See [qt_cc_moc](docs.md#qt_cc_moc).",
        "qmltyperegistrar": "The path to Qt's `qmltyperegistrar` tool. See [qt_qml_cc_module](docs.md#qt_qml_cc_module).",
        "rcc": "The path to Qt's `rcc` tool. See [qt_cc_rcc](docs.md#qt_cc_rcc).",
        "uic": "The path to Qt's `uic` tool. See [qt_cc_uic](docs.md#qt_cc_uic).",
    },
)

QtConfInfo = provider(
    fields = {
        "values": "A dictionary with Qt configuration values (qmake -query + derived fields).",
    },
)

def _qt_toolchain_impl(ctx):
    metatypes = {name: target.files.to_list()[0] for name, target in ctx.attr.metatypes.items()}

    toolchain_info = platform_common.ToolchainInfo(
        qtinfo = QtInfo(
            balsam = ctx.executable.balsam,
            moc = ctx.executable.moc,
            qmltyperegistrar = ctx.executable.qmltyperegistrar,
            rcc = ctx.executable.rcc,
            uic = ctx.executable.uic,
            metatypes = metatypes,
            headers = ctx.attr.headers,
        ),
        qtconf = QtConfInfo(
            values = ctx.attr.qtconf,
        ),
    )
    return [toolchain_info]

qt_toolchain = rule(
    implementation = _qt_toolchain_impl,
    doc = """
Implements Qt's toolchain to build Qt and QtQuick applications with Bazel.

Qt support: Qt5 and Qt6.

Testing: Qt 5.15 and Qt 6.4+.

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
        "metatypes": attr.string_keyed_label_dict(
            allow_files = [".json"],
            default = {},
            doc = "Mapping from Qt module target names to their metatype json files.",
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
        "qtconf": attr.string_dict(
            mandatory = True,
            doc = "Qt configuration values used by rules/macros for runtime defaults.",
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
