load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@io_bazel_stardoc//stardoc:stardoc.bzl", "stardoc")

toolchain_type(
    name = "toolchain_type",
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "bzl_rules",
    srcs = [
        "private/balsam.bzl",
        "private/moc.bzl",
        "private/qml.bzl",
        "private/rcc.bzl",
        "private/uic.bzl",
        "private/utils.bzl",
    ],
    deps = [
        "@bazel_skylib//lib:collections",
    ],
)

stardoc(
    name = "docs",
    out = "docs.md",
    input = "defs.bzl",
    symbol_names = [
        "qt_qrc",
        "qt_cc_rcc",
        "qt_cc_uic",
        "qt_cc_moc",
        "qt_cc_moc_import",
        "qt_qml_cc_module",
        "qt_balsam",
        "qt_cc_library",
        "qt_cc_binary",
        "qt_qml_import",
    ],
    deps = [":bzl_rules"],
)

stardoc(
    name = "qt_local_repo_docs",
    out = "qt_local_repo-docs.md",
    input = "qt_local_repo.bzl",
    deps = [
        ":bzl_rules",
        "@bazel_skylib//lib:paths",
        "@bazel_skylib//lib:structs",
    ],
)

stardoc(
    name = "qt_http_repo_docs",
    out = "qt_http_repo-docs.md",
    input = "qt_http_repo.bzl",
    deps = [
        ":bzl_rules",
        "@bazel_skylib//lib:paths",
        "@bazel_skylib//lib:structs",
    ],
)

stardoc(
    name = "providers_docs",
    out = "providers-docs.md",
    input = "private/utils.bzl",
)

stardoc(
    name = "toolchain_docs",
    out = "toolchain-docs.md",
    input = "toolchain.bzl",
    deps = ["@bazel_skylib//lib:paths"],
)
