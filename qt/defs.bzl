"""A set of convinience macros for using Qt's rules with Bazel."""

load("@bazel_skylib//lib:collections.bzl", "collections")
load("@qt//:qtconf.bzl", "QT_INSTALL_PLUGINS", "QT_INSTALL_QML")  # needs to be commented upon docs generation
load(":private/balsam.bzl", "balsam")
load(":private/moc.bzl", "moc_hdrs", "moc_srcs")
load(":private/qml.bzl", "qml_module")
load(":private/rcc.bzl", "qrc", "rcc")
load(":private/uic.bzl", "uic")

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
        Sets `QT_PLUGIN_PATH`, `QML2_IMPORT_PATH` (Qt5) and `QML_IMPORT_PATH` (Qt6) environment variables.
      qml_modules: A list of [qt_qml_import](#qt_qml_import) targets which will be available during runtime.
      **kwargs: Additional arguments for `cc_binary` rule.
    """

    # inject QML import path
    env = kwargs.pop("env", {})
    package_root = native.package_name()
    import_paths = [
        package_root,
        QT_INSTALL_QML,
    ]
    import_paths.extend(["{root}/{path}".format(root = package_root, path = path) for path in qml_import_paths])
    import_paths = collections.uniq(import_paths)
    env[_QML_IMPORT_PATH] = ":".join(import_paths)
    env[_QML2_IMPORT_PATH] = ":".join(import_paths)
    env[_QT_PLUGIN_PATH] = QT_INSTALL_PLUGINS
    kwargs["env"] = env

    _qt_cc_target(
        native.cc_binary,
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
        data = kwargs.pop("data", qml_modules),
        **kwargs
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
