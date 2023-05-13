"""Repository rule to make locally installed Qt available in Bazel."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:structs.bzl", "structs")
load(":private/utils.bzl", "QT_REPO_INSTALL_FILE", "version_triplet")

_BUILD_CONTENT_PROLOGUE = """load("@rules_cc//cc:defs.bzl", "cc_library")
load("@com_github_kklochkov_rules_qt//qt:toolchain.bzl", "qt_toolchain")
load(":qtconf.bzl",
  "QT_VERSION",
  "INSTALL_PREFIX",
  "TOOLS_PREFIX",
  "EXTRA_TOOLS_PREFIX",
  "LIBS_PREFIX",
  "HEADERS_PREFIX",
)

package(default_visibility = ["//visibility:public"])"""

_BUILD_CONTENT_CC_TARGET_PROLOGUE = """
cc_library(
    name = "{lib_name}","""

_BUILD_CONTENT_CC_TARGET_SRCS = """    srcs = [{libs}],"""

_BUILD_CONTENT_CC_TARGET_OSX_LINKOPTS = """    linkopts = [
        # TODO: to correctly work with the sandbox, rpath needs to use relative paths
        #"-F{{QT_INSTALL_PREFIX}}/{{LIBS_PREFIX}}".format(QT_INSTALL_PREFIX = QT_INSTALL_PREFIX, LIBS_PREFIX = LIBS_PREFIX),
        "-F{{INSTALL_PREFIX}}/{{LIBS_PREFIX}}".format(INSTALL_PREFIX = INSTALL_PREFIX, LIBS_PREFIX = LIBS_PREFIX),
        "-framework {lib_name}",
    ],"""

_BUILD_CONTENT_CC_TARGET_HDRS = """    hdrs = glob(["{{HEADERS_PREFIX}}/{lib_name}/**".format(HEADERS_PREFIX = HEADERS_PREFIX)], allow_empty = False),
    includes = [
      HEADERS_PREFIX,
      # private headers
      "{{HEADERS_PREFIX}}/{lib_name}/{{QT_VERSION}}".format(HEADERS_PREFIX = HEADERS_PREFIX, QT_VERSION = QT_VERSION),
      "{{HEADERS_PREFIX}}/{lib_name}/{{QT_VERSION}}/{lib_name}".format(HEADERS_PREFIX = HEADERS_PREFIX, QT_VERSION = QT_VERSION),
    ],
    strip_include_prefix = "{{HEADERS_PREFIX}}/{lib_name}".format(HEADERS_PREFIX = HEADERS_PREFIX),"""

_BUILD_CONTENT_CC_TARGET_DEPS = """    deps = [{deps}],"""

_BUILD_CONTENT_CC_TARGET_EPILOGUE = ")"

_BUILD_CONTENT_CC_TARGET_ALL_HEADERS = """
cc_library(
  name = "all_headers",
  hdrs = glob(["{{HEADERS_PREFIX}}/**".format(HEADERS_PREFIX = HEADERS_PREFIX)], allow_empty = False),
  includes = [HEADERS_PREFIX, {includes}],
)"""

_BUILD_CONTENT_EPILOGUE = """
filegroup(
  name = "metatypes",
  srcs = glob(["{LIBS_PREFIX}/metatypes/*.json".format(LIBS_PREFIX = LIBS_PREFIX)], allow_empty = False),
)

qt_toolchain(
    name = "qt_unix",
    balsam = ":{EXTRA_TOOLS_PREFIX}/balsam".format(EXTRA_TOOLS_PREFIX = EXTRA_TOOLS_PREFIX),
    metatypes = ":metatypes",
    moc = ":{TOOLS_PREFIX}/moc".format(TOOLS_PREFIX = TOOLS_PREFIX),
    qmltyperegistrar = ":{TOOLS_PREFIX}/qmltyperegistrar".format(TOOLS_PREFIX = TOOLS_PREFIX),
    rcc = ":{TOOLS_PREFIX}/rcc".format(TOOLS_PREFIX = TOOLS_PREFIX),
    uic = ":{TOOLS_PREFIX}/uic".format(TOOLS_PREFIX = TOOLS_PREFIX),
    headers = ":all_headers",
)

toolchain(
    name = "qt_linux_x86_64_toolchain",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    toolchain = ":qt_unix",
    toolchain_type = "@com_github_kklochkov_rules_qt//qt:toolchain_type",
)

toolchain(
    name = "qt_linux_arm64_toolchain",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:arm64",
    ],
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:arm64",
    ],
    toolchain = ":qt_unix",
    toolchain_type = "@com_github_kklochkov_rules_qt//qt:toolchain_type",
)

toolchain(
    name = "qt_osx_arm64_toolchain",
    exec_compatible_with = [
        "@platforms//os:osx",
        "@platforms//cpu:arm64",
    ],
    target_compatible_with = [
        "@platforms//os:osx",
        "@platforms//cpu:arm64",
    ],
    toolchain = ":qt_unix",
    toolchain_type = "@com_github_kklochkov_rules_qt//qt:toolchain_type",
)"""

_QtLibsContext = provider(
    doc = """
Provides structured information about host Qt's headers and libraries.
This provider is used to generate a `cc_library` target.
""",
    fields = {
        "deps": "A list of strings, dependencies of a library that will be placed `cc_library`'s `deps`",
        "has_headers": "A boolean flag that indicates if a library has associated headers",
        "is_osx_framework": "A boolean flag, macOS only, that indicates if a library is represented as macOS framework",
        "libs": "A list of strings,  list of libraries that will be accessible in Bazel",
        "original_path": "A string, the original path where libraries can be found on a host",
    },
)

def _relativize(path, start):
    """Helper function to relativize qt.conf paths by using `paths`.
    If `result` path equals `start` then current Bazel repository path is used
    to create correct symlink target.
    """
    result = paths.relativize(path, start)
    return "." if result == path else result

def _build_qtconf(repository_ctx, qt_dir):
    """Helper function to fill up qtconf convinience struct."""
    args = list()
    args.append("{qt_dir}/bin/qmake".format(qt_dir = qt_dir))
    args.append("-query")
    result = repository_ctx.execute(args)

    if result.return_code != 0:
        fail(result.stderr)

    qtconf = dict()
    for line in result.stdout.splitlines():
        key_value_pair = line.split(":")
        qtconf[key_value_pair[0]] = key_value_pair[1]

    qt_major, qt_minor, _ = version_triplet(qtconf["QT_VERSION"])
    qt_version = "Qt{version}".format(version = qt_major)
    is_qt6 = qt_major == 6

    original_vars = struct(
        QT_VERSION = qtconf["QT_VERSION"],
        QT_INSTALL_PREFIX = qtconf["QT_INSTALL_PREFIX"],
        QT_INSTALL_BINS = qtconf["QT_INSTALL_BINS"],
        QT_INSTALL_LIBEXECS = qtconf["QT_INSTALL_LIBEXECS"],
        QT_INSTALL_LIBS = qtconf["QT_INSTALL_LIBS"],
        QT_INSTALL_HEADERS = qtconf["QT_INSTALL_HEADERS"],
        QT_INSTALL_DATA = qtconf["QT_INSTALL_DATA"],
        QT_INSTALL_ARCHDATA = qtconf["QT_INSTALL_ARCHDATA"],
        QT_INSTALL_QML = qtconf["QT_INSTALL_QML"],
        QT_INSTALL_PLUGINS = qtconf["QT_INSTALL_PLUGINS"],
    )

    install_prefix = original_vars.QT_INSTALL_PREFIX
    bins_prefix = _relativize(original_vars.QT_INSTALL_BINS, install_prefix)
    libexecs_prefix = _relativize(original_vars.QT_INSTALL_LIBEXECS, install_prefix)

    extra_vars = struct(
        INSTALL_PREFIX = repository_ctx.path("."),
        TOOLS_PREFIX = libexecs_prefix if is_qt6 else bins_prefix,
        EXTRA_TOOLS_PREFIX = bins_prefix,
        LIBS_PREFIX = _relativize(original_vars.QT_INSTALL_LIBS, install_prefix),
        HEADERS_PREFIX = _relativize(original_vars.QT_INSTALL_HEADERS, install_prefix),
        DATA_PREFIX = _relativize(original_vars.QT_INSTALL_DATA, install_prefix),
        ARCHDATA_PREFIX = _relativize(original_vars.QT_INSTALL_ARCHDATA, install_prefix),
        QML_PREFIX = _relativize(original_vars.QT_INSTALL_QML, install_prefix),
        PLUGINS_PREFIX = _relativize(original_vars.QT_INSTALL_PLUGINS, install_prefix),
    )

    return struct(
        major = qt_major,
        minor = qt_minor,
        is_qt6 = qt_major == 6,
        lib_prefix = "libQt{major_version}".format(major_version = qt_major),
        original_vars = original_vars,
        extra_vars = extra_vars,
    )

def _struct_to_list(s):
    """Helper function that converts given struct `s` to a key-value list."""
    return ["{key}=\"{value}\"".format(key = key, value = value) for key, value in structs.to_dict(s).items()]

def _write_qtconf(repository_ctx, qtconf):
    """Helper function to store `qtconf` struct in to `qtconf.bzl`."""
    qtconf_content = list()
    qtconf_content.append("# qmake generated variables")
    qtconf_content.extend(_struct_to_list(qtconf.original_vars))
    qtconf_content.append("# Custom prefixes")
    qtconf_content.extend(_struct_to_list(qtconf.extra_vars))
    repository_ctx.file("qtconf.bzl", "\n".join(qtconf_content))

def _try_create_symlink(repository_ctx, target, link_name):
    """Helper function that attempts to create a symlink if it doesn't already exist."""
    symlink = repository_ctx.path("{prefix}/{basename}".format(
        prefix = link_name,
        basename = repository_ctx.path(target).basename,
    ))
    if symlink.exists != True:
        repository_ctx.symlink(target, symlink)

def _create_tools_symlinks(repository_ctx, qtconf):
    """Helper function that creates symlinks for Qt's tools."""
    path_tuples = [
        (qtconf.original_vars.QT_INSTALL_BINS, qtconf.extra_vars.EXTRA_TOOLS_PREFIX),
        (qtconf.original_vars.QT_INSTALL_LIBEXECS, qtconf.extra_vars.TOOLS_PREFIX),
    ]
    for source_path, destination_path in path_tuples:
        source_folder = repository_ctx.path(source_path)
        if source_folder.exists != True:
            continue
        for path in source_folder.readdir():
            if path.basename in repository_ctx.attr._reuired_tools:
                _try_create_symlink(repository_ctx, path, destination_path)

def _create_data_symlinks(repository_ctx, qtconf):
    """Helper function that creates symlinks for Qt's data."""
    path_tuples = [
        (qtconf.original_vars.QT_INSTALL_DATA, qtconf.extra_vars.DATA_PREFIX),
        (qtconf.original_vars.QT_INSTALL_ARCHDATA, qtconf.extra_vars.ARCHDATA_PREFIX),
        (qtconf.original_vars.QT_INSTALL_PLUGINS, qtconf.extra_vars.PLUGINS_PREFIX),
        (qtconf.original_vars.QT_INSTALL_QML, qtconf.extra_vars.QML_PREFIX),
    ]
    for source_path, destination_path in path_tuples:
        for path in repository_ctx.path(source_path).readdir():
            _try_create_symlink(repository_ctx, path, destination_path)

def _create_metatypes_symlink(repository_ctx, qtconf):
    """Helper function that creates symlinks for Qt's metatypes."""
    path = repository_ctx.path("{prefix}/metatypes".format(prefix = qtconf.original_vars.QT_INSTALL_LIBS))
    _try_create_symlink(repository_ctx, path, qtconf.extra_vars.LIBS_PREFIX)

def _create_headers_symlinks(repository_ctx, qtconf):
    """Helper function that creates symlinks for Qt's headers."""
    result = dict()
    for path in repository_ctx.path(qtconf.original_vars.QT_INSTALL_HEADERS).readdir():
        if path.basename.startswith("Qt") != True:
            continue

        _try_create_symlink(repository_ctx, path, qtconf.extra_vars.HEADERS_PREFIX)

        result[path.basename] = _QtLibsContext(
            original_path = path,
            libs = list(),
            has_headers = True,
            is_osx_framework = False,
            deps = list(),
        )
    return result

def _create_libs_symlinks(repository_ctx, qt_libs_context, qtconf):
    """Helper function that creates symlinks for Qt's libs."""
    for path in repository_ctx.path(qtconf.original_vars.QT_INSTALL_LIBS).readdir():
        # skip non lib files
        is_osx_framework = path.basename.endswith(".framework")
        is_prl = path.basename.endswith(".prl")
        is_la = path.basename.endswith(".la")
        if is_prl or is_la or (not is_osx_framework and not path.basename.startswith(qtconf.lib_prefix)):
            continue

        _try_create_symlink(repository_ctx, path, qtconf.extra_vars.LIBS_PREFIX)

        basename = path.basename.split(".")[0]
        lib_name = basename.replace(qtconf.lib_prefix, "Qt")
        if lib_name in qt_libs_context:
            qt_lib_context = qt_libs_context[lib_name]
            qt_lib_context.libs.append(path.basename)
            qt_libs_context[lib_name] = _QtLibsContext(
                original_path = qt_lib_context.original_path,
                libs = qt_lib_context.libs,
                has_headers = qt_lib_context.has_headers,
                is_osx_framework = is_osx_framework,
                deps = qt_lib_context.deps,
            )
        else:
            qt_libs_context[lib_name] = _QtLibsContext(
                original_path = path,
                libs = [path.basename],
                has_headers = False,
                is_osx_framework = is_osx_framework,
                deps = list(),
            )

    return qt_libs_context

def _join_libs(libs):
    """Helper function that consolidates `libs` list in a string."""
    return ",".join(["\"{{LIBS_PREFIX}}/{lib}\".format(LIBS_PREFIX = LIBS_PREFIX)".format(lib = lib) for lib in libs])

def _join_deps(deps):
    """Helper function that consolidates `deps` list in a string."""
    return ",".join(["\"{dep}\"".format(dep = dep) for dep in deps])

def _join_includes(qtconf, libs):
    """Helper function that consolidates `includes` list in a string."""
    return ",".join(["\"{headers_prefix}/{lib}\"".format(headers_prefix = qtconf.extra_vars.HEADERS_PREFIX, lib = lib) for lib in libs])

def _qt_local_repo_impl(repository_ctx):
    """Repository rule's implementation function."""

    if repository_ctx.attr.path and repository_ctx.attr.qt_http_repo:
        fail("Either path or qt_http_repo can be provided.")

    if len(repository_ctx.attr.path) == 0 and repository_ctx.attr.qt_http_repo == None:
        fail("Either path or qt_http_repo must be provided.")

    qt_dir = repository_ctx.attr.path
    if repository_ctx.attr.qt_http_repo:
        qt_dir = repository_ctx.path(repository_ctx.attr.qt_http_repo.relative(QT_REPO_INSTALL_FILE))
        qt_dir = repository_ctx.read(qt_dir).splitlines()[0]

    qtconf = _build_qtconf(repository_ctx, qt_dir)
    _write_qtconf(repository_ctx, qtconf)

    print("Qt {QT_VERSION} installed in {QT_INSTALL_PREFIX} will be used.".format(
        QT_VERSION = qtconf.original_vars.QT_VERSION,
        QT_INSTALL_PREFIX = qtconf.original_vars.QT_INSTALL_PREFIX,
    ))

    content = list()
    content.append(_BUILD_CONTENT_PROLOGUE)

    # create symlinks to make Bazel aware of relevant files
    _create_tools_symlinks(repository_ctx, qtconf)
    _create_data_symlinks(repository_ctx, qtconf)
    _create_metatypes_symlink(repository_ctx, qtconf)

    qt_libs_context = _create_headers_symlinks(repository_ctx, qtconf)
    qt_libs_context = _create_libs_symlinks(repository_ctx, qt_libs_context, qtconf)

    # add QtQmlIntegration for Qt6.3 and later
    if qtconf.major == 6 and qtconf.minor >= 3:
        qt_libs_context["QtQml"].deps.append(":QtQmlIntegration")

    # render targets
    for lib_name, lib_context in qt_libs_context.items():
        content.append(_BUILD_CONTENT_CC_TARGET_PROLOGUE.format(lib_name = lib_name))
        if len(lib_context.libs) != 0:
            if lib_context.is_osx_framework:
                content.append(_BUILD_CONTENT_CC_TARGET_OSX_LINKOPTS.format(lib_name = lib_name))
            else:
                content.append(_BUILD_CONTENT_CC_TARGET_SRCS.format(libs = _join_libs(lib_context.libs)))
        if lib_context.has_headers:
            content.append(_BUILD_CONTENT_CC_TARGET_HDRS.format(lib_name = lib_name))
        if len(lib_context.deps) != 0:
            content.append(_BUILD_CONTENT_CC_TARGET_DEPS.format(deps = _join_deps(lib_context.deps)))
        content.append(_BUILD_CONTENT_CC_TARGET_EPILOGUE)

    # add last bits
    content.append(_BUILD_CONTENT_CC_TARGET_ALL_HEADERS.format(includes = _join_includes(qtconf, qt_libs_context.keys())))
    content.append(_BUILD_CONTENT_EPILOGUE)

    repository_ctx.file("BUILD.bazel", "\n".join(content))

qt_local_repo = repository_rule(
    implementation = _qt_local_repo_impl,
    doc = """
Repository rule that allows the use of locally installed Qt to be used with Bazel.

The rules invokes `qmake` which should exist in the provided `path` attribute,
collects information about Qt's installations paths and makes it accessible to other rules
by exporting `qtconf.bzl`. Creates symlinks to Qt's libraries, includes, plugins and QtQuick imports,
declares corresponding `cc_library`'es and populates toolchain with required tools for building Qt targets.

`qtconf.bzl` contains the same information as original Qt's conf (https://doc.qt.io/qt-5/qt-conf.html),
adjusted to be used in Bazel `BUILD` files.

## NOTE:

The repository rule autogenerates all discovered Qt's libraries and doesn't try to establish logical dependencies
between modules.
Therefore consumers of the repository will have to add Qt dependency targets manually to have a successful build.

## Example:

**linux:** `WORKSPACE`
```
load("@com_github_kklochkov_rules_qt//qt:qt_local_repo.bzl", "qt_local_repo")

# linux
qt_local_repo(
    name = "qt",
    path = "/usr/lib/qt6",
)
```

**macOS:** `WORKSPACE`
```
load("@com_github_kklochkov_rules_qt//qt:qt_local_repo.bzl", "qt_local_repo")

qt_local_repo(
    name = "qt",
    path = "/opt/homebrew/opt/qt5",
)
```

**qtconf.bzl**
`BUILD`
```
load("@qt//:qtconf.bzl", "QT_VERSION")
```
""",
    attrs = {
        "path": attr.string(doc = """
The path to locally installed Qt's folder where `qmake` is located, usually it is `bin` folder.
"""),
        "qt_http_repo": attr.label(allow_single_file = True, doc = """
The [qt_http_repo](qt_http_repo-docs.md) target name to boostrap Qt.
"""),
        "_reuired_tools": attr.string_list(default = ["moc", "rcc", "uic", "qmltyperegistrar", "balsam"]),
    },
    local = True,
)
