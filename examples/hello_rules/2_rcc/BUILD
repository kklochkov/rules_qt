load("@com_github_kklochkov_rules_qt//qt:defs.bzl", "qt_cc_binary", "qt_cc_rcc", "qt_qrc")
load("@rules_cc//cc:defs.bzl", "cc_binary")

# Example of `qt_qrc` and `qt_cc_rcc` usage.
qt_qrc(
    name = "qrc",
    # Provide existing`qrc` file.
    srcs = ["resources.qrc"],
    data = ["text.txt"],
)

qt_cc_rcc(
    name = "resources",
    srcs = [":qrc"],
)

cc_binary(
    name = "cc_binary",
    srcs = [
        "main.cpp",
        ":resources",
    ],
    deps = ["@qt//:QtCore"],
)

qt_qrc(
    name = "qrc_autogen",
    data = ["text.txt"],
    # Note that neither `srcs` nor `prefix` are provided.
    # Empty `srcs` attribute triggers the rule to auto generate `qrc`.
)

qt_cc_rcc(
    name = "resources_autogen",
    srcs = [":qrc_autogen"],
)

cc_binary(
    name = "cc_binary_autogen",
    srcs = [
        "main.cpp",
        ":resources_autogen",
    ],
    deps = ["@qt//:QtCore"],
)

# Example of `qt_cc_binary` macro usage.
# In its essence, `qt_cc_binary` macro usage the same approach as above,
# but implementation details are nicely hidden from the user.
qt_cc_binary(
    name = "qt_cc_binary",
    srcs = ["main.cpp"],
    qrc_srcs = [":qrc"],
    deps = ["@qt//:QtCore"],
)

qt_cc_binary(
    name = "qt_cc_binary_autogen",
    srcs = ["main.cpp"],
    qrc_srcs = [":qrc_autogen"],
    deps = ["@qt//:QtCore"],
)
