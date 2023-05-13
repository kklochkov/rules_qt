"""Rules that allow to use [Qt's rcc](https://doc.qt.io/qt-5/rcc.html) with Bazel."""

load(":private/utils.bzl", "QT_TOOLCHAIN", "QrcInfo")

def _gen_qrc(ctx):
    toolchain = ctx.toolchains[QT_TOOLCHAIN]

    indent = " " * 2
    content = ["<RCC>"]
    prefix_attr = " prefix=\"{prefix}\"".format(prefix = ctx.attr.prefix) if ctx.attr.prefix else ""
    content.append("{indent}<qresource{prefix_attr}>".format(indent = indent, prefix_attr = prefix_attr))

    inputs = list()
    for source in ctx.files.data:
        path = source.owner.name if source.owner != None else source.short_path
        content.append("{indent}{indent}<file>{path}</file>".format(
            indent = indent,
            path = path,
        ))

        # symlink resources to be accessible for rcc tool
        source_symlink = ctx.actions.declare_file(path)
        ctx.actions.symlink(output = source_symlink, target_file = source)
        inputs.append(source_symlink)

    content.append("{indent}</qresource>".format(indent = indent))
    content.append("</RCC>")

    qrc = ctx.actions.declare_file("{name}.qrc".format(name = ctx.label.name))
    ctx.actions.write(
        output = qrc,
        content = "\n".join(content),
    )

    return (qrc, inputs)

def _qrc_impl(ctx):
    toolchain = ctx.toolchains[QT_TOOLCHAIN]

    qrcs = list(ctx.files.srcs)
    if len(qrcs) != 0 and len(ctx.attr.prefix) != 0:
        print("Both 'srcs' and 'prefix' attributes are provided. The 'prefix' attibute will be inored.")

    data = list(ctx.files.data)
    if len(qrcs) == 0:
        qrc, data_symlinks = _gen_qrc(ctx)
        data.extend(data_symlinks)
        qrcs.append(qrc)

    return [
        DefaultInfo(files = depset(data)),
        QrcInfo(qrcs = qrcs, data = data),
    ]

qrc = rule(
    implementation = _qrc_impl,
    doc = """
The rule either exposes already available Qt's Resources files (`qrc`) via `srcs` attribute or generates one
for further use by the resource compiler ([qt_cc_rcc](#qt_cc_rcc) rule).

The information between `qt_qrc` and `qt_cc_rcc` rules are passed via [QrcInfo](providers-docs.md#QrcInfo) provider.

In case when `srcs` has values, the rule will generate the same amount of C++ sources as a number of `qrc` files.
When the attribute is empty, the rule will first generate a `qrc` file for all resources available in `data`
attribute and place them under specified `prefix` (by default it's empty).

If both `srcs` and `prefix` attributes are provided, the `prefix` will be ignored.

The `data` attribute should have all necessary files listed for successful code generation.
""",
    attrs = {
        "data": attr.label_list(
            allow_files = True,
            doc = """
A list of resources which will be propagated to [qt_cc_rcc](#qt_cc_rcc) via [QrcInfo](providers-docs.md#QrcInfo).

In case of auto `qrc` files generation, all files listed in this attribute will be part of the generated one.
""",
        ),
        "prefix": attr.string(
            doc = """
A prefix to logically group resources.

Only available for auto `qrc` file generation, i.e. when the `srcs` attribute is empty.
""",
        ),
        "srcs": attr.label_list(
            allow_files = [".qrc"],
            doc = """
A list of `qrc` files for will propagated to [qt_cc_rcc](#qt_cc_rcc) via [QrcInfo](providers-docs.md#QrcInfo).
""",
        ),
    },
    toolchains = [QT_TOOLCHAIN],
    provides = [DefaultInfo, QrcInfo],
)

def _rcc_impl(ctx):
    toolchain = ctx.toolchains[QT_TOOLCHAIN]

    cpps = list()
    for qrc in ctx.attr.srcs:
        qrc_info = qrc[QrcInfo]
        for qrc in qrc_info.qrcs:
            qrc_name = qrc.basename.replace(".qrc", "")
            cpp = ctx.actions.declare_file("qrc_{name}.cpp".format(name = qrc_name))
            cpps.append(cpp)

            initilizer_name = "{package}_{label}".format(package = ctx.label.package.replace("/", "_"), label = qrc_name)

            args = ctx.actions.args()
            args.add("--name", initilizer_name)
            args.add("--output", cpp)
            args.add(qrc)

            ctx.actions.run(
                inputs = [qrc] + qrc_info.data,
                outputs = [cpp],
                progress_message = "[Qt rcc]: generating {path}".format(path = cpp.short_path),
                executable = toolchain.qtinfo.rcc,
                arguments = [args],
            )

    return [DefaultInfo(files = depset(cpps))]

rcc = rule(
    implementation = _rcc_impl,
    doc = """
The rule generates C++ sources based on information provided via [QrcInfo](providers-docs.md#QrcInfo) mandatory provider.

As of now [qt_qrc](#qt_qrc) and [qt_balsam](#qt_balsam) rules use `QrcInfo` provider.
""",
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
            providers = [QrcInfo],
            doc = """
A list of targets that provide `QrcInfo`.
""",
        ),
    },
    toolchains = [QT_TOOLCHAIN],
)
