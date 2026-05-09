"""A set of convenience macros for using Qt's rules with Bazel."""

load(":private/balsam.bzl", "balsam")
load(":private/moc.bzl", "moc_hdrs", "moc_srcs")
load(":private/qml.bzl", "qml_module")
load(":private/rcc.bzl", "qrc", "rcc")
load(":private/uic.bzl", "uic")
load(":private/utils.bzl", "QT_TOOLCHAIN", "unique")

qt_qrc = qrc
qt_cc_rcc = rcc
qt_cc_uic = uic
qt_cc_moc = moc_hdrs
qt_cc_moc_import = moc_srcs
qt_qml_cc_module = qml_module
qt_balsam = balsam

def _qt_cc_target(
        cc_target,
        name,
        srcs = [],
        deps = [],
        moc_hdrs = None,
        moc_srcs = None,
        qrc_srcs = None,
        ui_srcs = None,
        qml_module_name = None,
        qml_module_major_version = None,
        qml_module_minor_version = None,
        **kwargs):
    extra_srcs = list()
    if qrc_srcs != None:
        target_name = "{name}_qt_resources".format(name = name)
        qt_cc_rcc(
            name = target_name,
            srcs = qrc_srcs,
        )
        extra_srcs.append(target_name)

    extra_deps = list()
    if ui_srcs != None:
        target_name = "{name}_qt_uis".format(name = name)
        qt_cc_uic(
            name = target_name,
            srcs = ui_srcs,
        )
        extra_deps.append(target_name)

    moc_hdrs_target = None
    if moc_hdrs != None:
        moc_hdrs_target = "{name}_qt_moc_hdrs".format(name = name)
        qt_cc_moc(
            name = moc_hdrs_target,
            hdrs = moc_hdrs,
        )
        extra_srcs.append(moc_hdrs_target)

    if moc_srcs != None:
        target_name = "{name}_qt_moc_srcs".format(name = name)
        qt_cc_moc_import(
            name = target_name,
            srcs = moc_srcs,
        )
        extra_deps.append(target_name)
        extra_srcs.extend(moc_srcs)

    if qml_module_name != None:
        target_name = "{name}_qt_qmltypes".format(name = name)
        qt_qml_cc_module(
            name = target_name,
            moc = moc_hdrs_target,
            module_name = qml_module_name,
            major_version = qml_module_major_version,
            minor_version = qml_module_minor_version,
            deps = deps,
        )
        extra_srcs.append(target_name)

    cc_target(
        name = name,
        srcs = srcs + extra_srcs,
        deps = deps + extra_deps,
        **kwargs
    )

def qt_cc_library(
        name,
        srcs = [],
        deps = [],
        moc_hdrs = None,
        moc_srcs = None,
        qrc_srcs = None,
        ui_srcs = None,
        qml_module_name = None,
        qml_module_major_version = None,
        qml_module_minor_version = None,
        **kwargs):
    """Convenience macro around Qt's rule and `cc_library`.

    Args:
      name: A unique name for this rule.
      srcs: See `cc_library`'s [srcs](https://bazel.build/reference/be/c-cpp#cc_library.srcs) attribute.
      deps: See `cc_library`'s [deps](https://bazel.build/reference/be/c-cpp#cc_library.deps) attribute.
      moc_hdrs: Headers for `moc`. See [qt_cc_moc](#qt_cc_moc) for more info.
      moc_srcs: Sources for `moc`. See [qt_cc_moc_import](#qt_cc_moc_import) for more info.
      qrc_srcs: `qrc` files for `rcc`. See [qt_cc_rcc](#qt_cc_rcc) for more info.
      ui_srcs: `ui` files for `uic`. See [qt_cc_uic](#qt_cc_uic) for more info.
      qml_module_name: A unique name of QML module. See [qt_qml_cc_module](#qt_qml_cc_module) for more info.
      qml_module_major_version: A major version of QML module. See [qt_qml_cc_module](#qt_qml_cc_module) for more info.
      qml_module_minor_version: A minor version of QML module. See [qt_qml_cc_module](#qt_qml_cc_module) for more info.
      **kwargs: Additional arguments for `cc_library` rule.
    """
    _qt_cc_target(
        native.cc_library,
        name,
        srcs,
        deps,
        moc_hdrs = moc_hdrs,
        moc_srcs = moc_srcs,
        qrc_srcs = qrc_srcs,
        ui_srcs = ui_srcs,
        qml_module_name = qml_module_name,
        qml_module_major_version = qml_module_major_version,
        qml_module_minor_version = qml_module_minor_version,
        alwayslink = True,
        **kwargs
    )

_QML_IMPORT_PATH = "QML_IMPORT_PATH"  # Qt 6 and later
_QML2_IMPORT_PATH = "QML2_IMPORT_PATH"
_QT_PLUGIN_PATH = "QT_PLUGIN_PATH"

def _qt_runtime_binary_impl(ctx):
    qtconf = ctx.toolchains[QT_TOOLCHAIN].qtconf.values
    package_root = ctx.attr.package_root

    import_paths = [package_root]
    default_qml_path = qtconf.get("QT_INSTALL_QML", "")
    qml_path = ctx.attr.qt_qml_path if ctx.attr.qt_qml_path != "" else default_qml_path
    if qml_path != "":
        import_paths.append(qml_path)
    import_paths.extend(["{root}/{path}".format(root = package_root, path = path) for path in ctx.attr.qml_import_paths])
    import_paths = unique(import_paths)

    env = dict(ctx.attr.env)
    qml_env_value = ":".join(import_paths)
    if _QML_IMPORT_PATH not in env:
        env[_QML_IMPORT_PATH] = qml_env_value
    if _QML2_IMPORT_PATH not in env:
        env[_QML2_IMPORT_PATH] = qml_env_value

    default_plugin_path = qtconf.get("QT_INSTALL_PLUGINS", "")
    plugin_path = ctx.attr.qt_plugin_path if ctx.attr.qt_plugin_path != "" else default_plugin_path
    if _QT_PLUGIN_PATH not in env:
        env[_QT_PLUGIN_PATH] = plugin_path

    launcher = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(
        output = launcher,
        target_file = ctx.executable.binary,
    )

    binary_info = ctx.attr.binary[DefaultInfo]
    runfiles = ctx.runfiles(files = [ctx.executable.binary])
    runfiles = runfiles.merge(binary_info.default_runfiles)
    return [
        DefaultInfo(
            executable = launcher,
            runfiles = runfiles,
        ),
        RunEnvironmentInfo(environment = env),
    ]

_qt_runtime_binary = rule(
    implementation = _qt_runtime_binary_impl,
    attrs = {
        "binary": attr.label(
            mandatory = True,
            executable = True,
            cfg = "target",
        ),
        "env": attr.string_dict(),
        "package_root": attr.string(mandatory = True),
        "qml_import_paths": attr.string_list(),
        "qt_plugin_path": attr.string(),
        "qt_qml_path": attr.string(),
    },
    executable = True,
    toolchains = [QT_TOOLCHAIN],
)

def qt_cc_binary(
        name,
        srcs = [],
        deps = [],
        moc_hdrs = None,
        moc_srcs = None,
        qrc_srcs = None,
        ui_srcs = None,
        qml_module_name = None,
        qml_module_major_version = None,
        qml_module_minor_version = None,
        qml_import_paths = [],
        qml_modules = [],
        qt_qml_path = None,
        qt_plugin_path = None,
        **kwargs):
    """Convenience macro around Qt's rule and `cc_binary`.

    Args:
      name: A unique name for this rule.
      srcs: See `cc_binary`'s [srcs](https://bazel.build/reference/be/c-cpp#cc_binary.srcs) attribute.
      deps: See `cc_binary`'s [deps](https://bazel.build/reference/be/c-cpp#cc_binary.deps) attribute.
      moc_hdrs: Headers for `moc`. See [qt_cc_moc](#qt_cc_moc) for more info.
      moc_srcs: Sources for `moc`. See [qt_cc_moc_import](#qt_cc_moc_import) for more info.
      qrc_srcs: `qrc` files for `rcc`. See [qt_cc_rcc](#qt_cc_rcc) for more info.
      ui_srcs: `ui` files for `uic`. See [qt_cc_uic](#qt_cc_uic) for more info.
      qml_module_name: A unique name of QML module. See [qt_qml_cc_module](#qt_qml_cc_module) for more info.
      qml_module_major_version: A major version of QML module. See [qt_qml_cc_module](#qt_qml_cc_module) for more info.
      qml_module_minor_version: A minor version of QML module. See [qt_qml_cc_module](#qt_qml_cc_module) for more info.
      qml_import_paths: A list of paths where the QtQml engine should look for additional imports.
        Sets `QML2_IMPORT_PATH` (Qt5) and `QML_IMPORT_PATH` (Qt6) environment variables.
      qml_modules: A list of [qt_qml_import](#qt_qml_import) targets which will be available during runtime.
        Can be combined with `data`; both lists are merged.
      qt_qml_path: Optional path to Qt's built-in QML imports folder. If set, it is appended to
        `QML2_IMPORT_PATH` and `QML_IMPORT_PATH`.
      qt_plugin_path: Optional path to Qt's plugins folder. If set, it configures `QT_PLUGIN_PATH`.
      **kwargs: Additional arguments for `cc_binary` rule.
    """

    env = kwargs.pop("env", {})
    data = kwargs.pop("data", None)

    if data != None and qml_modules:
        # buildifier: disable=print
        print("qt_cc_binary: both 'data' and 'qml_modules' specified; merging them")

    runtime_data = (data or []) + qml_modules

    visibility = kwargs.pop("visibility", None)
    testonly = kwargs.pop("testonly", None)
    tags = kwargs.pop("tags", None)
    compatible_with = kwargs.pop("compatible_with", None)
    restricted_to = kwargs.pop("restricted_to", None)
    target_compatible_with = kwargs.pop("target_compatible_with", None)
    deprecation = kwargs.pop("deprecation", None)
    features = kwargs.pop("features", None)

    inner_name = "__qt_internal_{name}_cc_binary".format(name = name)
    compat_name = "{name}_cc_binary".format(name = name)

    if native.existing_rule(inner_name) != None:
        fail("qt_cc_binary: internal target name collision for '{target}'".format(target = inner_name))

    if native.existing_rule(compat_name) != None:
        fail("qt_cc_binary: compatibility target name collision for '{target}'".format(target = compat_name))

    _qt_cc_target(
        native.cc_binary,
        inner_name,
        srcs,
        deps,
        moc_hdrs = moc_hdrs,
        moc_srcs = moc_srcs,
        qrc_srcs = qrc_srcs,
        ui_srcs = ui_srcs,
        qml_module_name = qml_module_name,
        qml_module_major_version = qml_module_major_version,
        qml_module_minor_version = qml_module_minor_version,
        data = runtime_data,
        env = env,
        testonly = testonly,
        tags = tags,
        compatible_with = compatible_with,
        restricted_to = restricted_to,
        target_compatible_with = target_compatible_with,
        deprecation = deprecation,
        features = features,
        visibility = ["//visibility:private"],
        **kwargs
    )

    native.alias(
        name = compat_name,
        actual = ":{name}".format(name = inner_name),
        visibility = visibility,
        testonly = testonly,
        deprecation = deprecation,
    )

    _qt_runtime_binary(
        name = name,
        binary = ":{name}".format(name = inner_name),
        env = env,
        package_root = native.package_name(),
        qml_import_paths = qml_import_paths,
        qt_qml_path = qt_qml_path if qt_qml_path != None else "",
        qt_plugin_path = qt_plugin_path if qt_plugin_path != None else "",
        visibility = visibility,
        testonly = testonly,
        tags = tags,
        compatible_with = compatible_with,
        restricted_to = restricted_to,
        target_compatible_with = target_compatible_with,
        deprecation = deprecation,
        features = features,
    )

def qt_qml_import(name, srcs):
    """Convenience macro around `filegroup` to import QML module.

    The target then can be used as runtime deps of [qt_cc_binary](#qt_cc_binary)
    or compile time by using it in conjunction with [qt_qrc](#qt_qrc).

    It expects that the QML module provides `qmldir`.

    See [Qt 5 QtQml directory imports](https://doc.qt.io/qt-5/qtqml-syntax-directoryimports.html#directory-listing-qmldir-files)
    and [Qt 6 QtQml directory imports](https://doc.qt.io/qt-6.4/qtqml-syntax-directoryimports.html#directory-listing-qmldir-files) for additional info.

    Args:
      name: A unique name for this rule.
      srcs: A list of files that describe a QML module.
    """
    native.filegroup(
        name = name,
        srcs = srcs + ["qmldir"],
    )
