"""Rules that provide QtQuick/QtQml support for Bazel."""

load(":private/utils.bzl", "MocInfo", "QT_TOOLCHAIN")

def _resolve_qml_metatypes(ctx, deps):
    """Resolves Qt built-in metatypes File objects for qmltyperegistrar foreign-types."""
    metatypes = ctx.toolchains[QT_TOOLCHAIN].qtinfo.metatypes
    resolved = []
    for dep in deps:
        f = metatypes.get(dep.label.name)
        if f:
            resolved.append(f)
    return sorted(resolved, key = lambda f: f.path)

def _qml_module_impl(ctx):
    toolchain = ctx.toolchains[QT_TOOLCHAIN]

    # collect metatypes
    metatypes_json = ctx.actions.declare_file("{name}_metatypes.json".format(name = ctx.label.name))

    args = ctx.actions.args()
    args.add("--collect-json")
    args.add("-o", metatypes_json)
    args.add_all(ctx.attr.moc[MocInfo].jsons)

    ctx.actions.run(
        inputs = ctx.attr.moc[MocInfo].jsons,
        outputs = [metatypes_json],
        progress_message = "[Qt moc]: generating {path}".format(path = metatypes_json.short_path),
        executable = toolchain.qtinfo.moc,
        arguments = [args],
    )

    # run qmltyperegistration
    inputs = list()
    inputs.append(metatypes_json)

    outputs = list()
    qmltyperegistration = ctx.actions.declare_file("{name}_qmltyperegistrations".format(name = ctx.label.name))
    outputs.append(qmltyperegistration)

    qmltypes = ctx.actions.declare_file("{name}.qmltypes".format(name = ctx.label.name))
    outputs.append(qmltypes)

    # qmltyperegistrar must see only the relevant Qt built-in metatypes.
    # Passing the entire SDK metatype set can trigger duplicate C++ type
    # warnings (ODR-like diagnostics) when unrelated Qt modules define
    # colliding type names.
    metatypes = _resolve_qml_metatypes(ctx, ctx.attr.deps)
    inputs.extend(metatypes)

    args = ctx.actions.args()
    if metatypes:
        args.add("--foreign-types", ",".join([f.path for f in metatypes]))
    args.add("--generate-qmltypes", qmltypes)
    args.add("--import-name={module_name}".format(module_name = ctx.attr.module_name))
    args.add("--major-version={version}".format(version = ctx.attr.major_version))
    args.add("--minor-version={version}".format(version = ctx.attr.minor_version))
    args.add("-o", qmltyperegistration)
    args.add(metatypes_json)

    ctx.actions.run(
        inputs = inputs,
        outputs = outputs,
        progress_message = "[Qt qmltyperegistrar]: generating {path}".format(path = qmltyperegistration.short_path),
        executable = toolchain.qtinfo.qmltyperegistrar,
        arguments = [args],
    )

    # we need to fixup angle brackets includes in generated files to quoted ones
    cpp = ctx.actions.declare_file("{name}.cpp".format(name = qmltyperegistration.basename))
    outputs.append(cpp)

    substitution_pairs = list()
    for hdr in ctx.attr.moc[MocInfo].headers:
        substitution_pairs.append(
            ("<{old_name}>".format(old_name = hdr.basename), ("\"{new_name}\"".format(new_name = hdr.short_path))),
        )

    ctx.actions.expand_template(template = qmltyperegistration, output = cpp, substitutions = dict(substitution_pairs))

    return [DefaultInfo(files = depset(outputs))]

qml_module = rule(
    implementation = _qml_module_impl,
    doc = """
Collects metainformation, provided by [qt_cc_moc](#qt_cc_moc) via [MocInfo](providers-docs.md#MocInfo),
of available C++ QML types and generates C++ routines to register them as QML modules.

More info about QtQml C++ integration can be found here: [Qt5](https://doc.qt.io/qt-5/qtqml-cppintegration-definetypes.html)
and [Qt6](https://doc.qt.io/qt-6/qtqml-cppintegration-definetypes.html).
    """,
    attrs = {
        "major_version": attr.int(
            default = 1,
            doc = """
Major version of QML module.
""",
        ),
        "minor_version": attr.int(
            default = 0,
            doc = """
Minor version of QML module.
""",
        ),
        "moc": attr.label(
            mandatory = True,
            providers = [MocInfo],
            doc = """
A [qt_cc_moc](#qt_cc_moc) target that provides [MocInfo](providers-docs.md#MocInfo)
""",
        ),
        "module_name": attr.string(
            mandatory = True,
            doc = """
A name of a module under which it will be accessible in QML.
""",
        ),
        "deps": attr.label_list(
            doc = """
Dependencies used to infer which Qt built-in metatypes should be passed to qmltyperegistrar.
""",
        ),
    },
    toolchains = [QT_TOOLCHAIN],
)
