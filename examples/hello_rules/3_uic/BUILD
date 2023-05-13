load("@com_github_kklochkov_rules_qt//qt:defs.bzl", "qt_cc_binary", "qt_cc_uic")
load("@qt//:qtconf.bzl", "QT_INSTALL_PLUGINS", "QT_VERSION")
load("@rules_cc//cc:defs.bzl", "cc_binary")

# Example of `qt_cc_uic` usage.
qt_cc_uic(
    name = "ui",
    srcs = ["widget.ui"],
)

cc_binary(
    name = "cc_binary",
    srcs = ["main.cpp"],
    env = {
        "QT_PLUGIN_PATH": QT_INSTALL_PLUGINS,
        # Example of `qtconf.bzl`'s constants usage.
        # QT_VERSION gets propagated via environments
        # that the application can use it at runtime.
        "QT_VERSION": "Qt {QT_VERSION}: ".format(QT_VERSION = QT_VERSION),
    },
    deps = [
        # Note that produced by `qt_cc_uic` artifact (`:ui`)
        # must be added here to prevent compilation issues.
        ":ui",
        "@qt//:QtCore",
        "@qt//:QtGui",
        "@qt//:QtWidgets",
    ],
)

# Example of `qt_cc_binary` macro usage.
# In its essence, `qt_cc_binary` macro usage the same approach as above,
# but implementation details are nicely hidden from the user.
qt_cc_binary(
    name = "qt_cc_binary",
    srcs = ["main.cpp"],
    env = {
        # Example of `qtconf.bzl`'s constants usage.
        # QT_VERSION gets propagated via environments
        # that the application can use it at runtime.
        "QT_VERSION": "Qt {QT_VERSION}: ".format(QT_VERSION = QT_VERSION),
    },
    ui_srcs = ["widget.ui"],
    deps = [
        "@qt//:QtCore",
        "@qt//:QtGui",
        "@qt//:QtWidgets",
    ],
)
