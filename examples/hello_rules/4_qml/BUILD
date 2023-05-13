load("@com_github_kklochkov_rules_qt//qt:defs.bzl", "qt_cc_binary", "qt_cc_moc", "qt_cc_rcc", "qt_qml_cc_module", "qt_qrc")
load("@qt//:qtconf.bzl", "QT_INSTALL_PLUGINS", "QT_INSTALL_QML", "QT_VERSION")
load("@rules_cc//cc:defs.bzl", "cc_binary")

# Example of `qt_qrc`,`qt_cc_rcc`, `qt_cc_moc` and `qt_qml_cc_module` usage.
qt_qrc(
    name = "qrc",
    data = [
        "main.qml",
        "main_qt6.qml",
    ],
)

qt_cc_rcc(
    name = "resources",
    srcs = [":qrc"],
)

qt_cc_moc(
    name = "text_provider_moc_hdrs",
    hdrs = ["text_provider.h"],
)

qt_qml_cc_module(
    name = "text_provider",
    major_version = 2,  # if not provided, defaults to 1
    minor_version = 3,  # if not provided, defaults to 0
    moc = ":text_provider_moc_hdrs",
    module_name = "TextProvider",
)

cc_binary(
    name = "cc_binary",
    srcs = [
        "main.cpp",
        "text_provider.cpp",
        ":resources",  # Make resources compiled-in the final binary
        ":text_provider",
        ":text_provider_moc_hdrs",
    ],
    env = {
        "MAIN_QML_FOLDER": ":",  # load from qrc file
        "QML2_IMPORT_PATH": QT_INSTALL_QML,
        "QML_IMPORT_PATH": QT_INSTALL_QML,
        "QT_PLUGIN_PATH": QT_INSTALL_PLUGINS,
        # Example of `qtconf.bzl`'s constants usage.
        # QT_VERSION gets propagated via environments
        # that the application can use it at runtime.
        "QT_VERSION": "Qt {QT_VERSION} (compiled-in resources): ".format(QT_VERSION = QT_VERSION),
    },
    deps = [
        "@qt//:QtCore",
        "@qt//:QtGui",
        "@qt//:QtNetwork",
        "@qt//:QtQml",
        "@qt//:QtQuick",
        "@qt//:QtWidgets",
    ],
)

cc_binary(
    name = "cc_binary_runtime_resources",
    srcs = [
        "main.cpp",
        "text_provider.cpp",
        ":resources",  # Make resources compiled-in the final binary
        ":text_provider",
        ":text_provider_moc_hdrs",
    ],
    data = [":qrc"],  # Make resources available at runtime for the final binary
    env = {
        "MAIN_QML_FOLDER": "hello_rules/4_qml",  # load from the path
        "QML2_IMPORT_PATH": QT_INSTALL_QML,
        "QML_IMPORT_PATH": QT_INSTALL_QML,
        "QT_PLUGIN_PATH": QT_INSTALL_PLUGINS,
        # Example of `qtconf.bzl`'s constants usage.
        # QT_VERSION gets propagated via environments
        # that the application can use it at runtime.
        "QT_VERSION": "Qt {QT_VERSION} (runtime resources): ".format(QT_VERSION = QT_VERSION),
    },
    deps = [
        "@qt//:QtCore",
        "@qt//:QtGui",
        "@qt//:QtNetwork",
        "@qt//:QtQml",
        "@qt//:QtQuick",
        "@qt//:QtWidgets",
    ],
)

# Example of `qt_cc_binary` macro usage.
# In its essence, `qt_cc_binary` macro usage the same approach as above,
# but implementation details are nicely hidden from the user.
qt_cc_binary(
    name = "qt_cc_binary",
    srcs = [
        "main.cpp",
        "text_provider.cpp",
    ],
    env = {
        "MAIN_QML_FOLDER": ":",  # load from qrc file
        # Example of `qtconf.bzl`'s constants usage.
        # QT_VERSION gets propagated via environments
        # that the application can use it at runtime.
        "QT_VERSION": "Qt {QT_VERSION} (compiled-in resources): ".format(QT_VERSION = QT_VERSION),
    },
    moc_hdrs = ["text_provider.h"],
    qml_module_major_version = 2,  # if not provided, defaults to 1
    qml_module_minor_version = 3,  # if not provided, defaults to 0
    qml_module_name = "TextProvider",
    qrc_srcs = [":qrc"],  # Make resources compiled-in the final binary
    deps = [
        "@qt//:QtCore",
        "@qt//:QtGui",
        "@qt//:QtNetwork",
        "@qt//:QtQml",
        "@qt//:QtQuick",
        "@qt//:QtWidgets",
    ],
)

qt_cc_binary(
    name = "qt_cc_binary_runtime_resources",
    srcs = [
        "main.cpp",
        "text_provider.cpp",
    ],
    data = [":qrc"],  # Make resources available at runtime for the final binary
    env = {
        "MAIN_QML_FOLDER": "hello_rules/4_qml",  # load from the path
        # Example of `qtconf.bzl`'s constants usage.
        # QT_VERSION gets propagated via environments
        # that the application can use it at runtime.
        "QT_VERSION": "Qt {QT_VERSION} (runtime resources): ".format(QT_VERSION = QT_VERSION),
    },
    moc_hdrs = ["text_provider.h"],
    qml_module_major_version = 2,  # if not provided, defaults to 1
    qml_module_minor_version = 3,  # if not provided, defaults to 0
    qml_module_name = "TextProvider",
    deps = [
        "@qt//:QtCore",
        "@qt//:QtGui",
        "@qt//:QtNetwork",
        "@qt//:QtQml",
        "@qt//:QtQuick",
        "@qt//:QtWidgets",
    ],
)
