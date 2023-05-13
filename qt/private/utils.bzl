"""Providers to exchange information between Qt's rules."""

QT_TOOLCHAIN = "@com_github_kklochkov_rules_qt//qt:toolchain_type"
QT_REPO_INSTALL_FILE = "install"

MocInfo = provider(fields = {
    "headers": "A list of headers required by `moc`.",
    "jsons": "A list of generated metatype information in `json` format. Consumed by [qt_qml_cc_module](docs.md#qt_qml_cc_module).",
})

QrcInfo = provider(fields = {
    "data": "A list of resources transitively required by [qt_cc_rcc](docs.md#qt_cc_rcc).",
    "qrcs": "A list of available or generated `qrc` files by [qt_qrc](docs.md#qt_qrc) rule.",
})

def version_triplet(version):
    """Helper function to convert given string `version` to a triplet of integers representing major, minor and patch version.

    Args:
      version: A string that contains the version triplet.
    """

    major, minor, patch = [int(v) for v in version.split(".")][:3]
    return major, minor, patch
