load("@com_github_kklochkov_rules_qt//qt:defs.bzl", "qt_cc_binary", "qt_cc_moc", "qt_cc_moc_import")
load("@rules_cc//cc:defs.bzl", "cc_binary")

# Example of `qt_cc_moc` and `qt_cc_moc_import` usage.
qt_cc_moc(
    name = "moc_hdrs",
    hdrs = ["external_object.h"],
)

qt_cc_moc_import(
    name = "moc_srcs",
    srcs = ["main.cpp"],
)

cc_binary(
    name = "cc_binary",
    srcs = [
        # Note that `external_object.h` is not explicitly added here,
        # it gets transitively propagated by the `qt_cc_moc` rule.
        "external_object.cpp",
        "main.cpp",
        ":moc_hdrs",
    ],
    deps = [
        # Note that produced by `qt_cc_moc_import` artifact (`:moc_srcs`)
        # must be added here to prevent compilation issues.
        ":moc_srcs",
        "@qt//:QtCore",
    ],
)

# Example of `qt_cc_binary` macro usage.
# In its essence, `qt_cc_binary` macro usage the same approach as above,
# but implementation details are nicely hidden from the user.
qt_cc_binary(
    name = "qt_cc_binary",
    srcs = ["external_object.cpp"],
    moc_hdrs = ["external_object.h"],
    # note that `main.cpp` doesn't have to be explicitly added to `srcs`,
    # it gets transitively propagated by `qt_cc_moc_import` rule.
    moc_srcs = ["main.cpp"],
    deps = ["@qt//:QtCore"],
)
