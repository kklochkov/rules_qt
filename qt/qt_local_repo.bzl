"""Repository rule to make locally installed Qt available in Bazel."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:structs.bzl", "structs")
load(":private/utils.bzl", "unique", "version_triplet")

_BUILD_CONTENT_PROLOGUE = """load("@rules_qt//qt:toolchain.bzl", "qt_toolchain")
load("@rules_cc//cc:defs.bzl", "cc_library")
load(":qtconf.bzl",
  "QT_VERSION",
  "INSTALL_PREFIX",
  "TOOLS_PREFIX",
  "EXTRA_TOOLS_PREFIX",
  "LIBS_PREFIX",
  "HEADERS_PREFIX",
  "QT_INSTALL_LIBS",
  "METATYPES",
)

package(default_visibility = ["//visibility:public"])"""

_BUILD_CONTENT_CC_TARGET_PROLOGUE = """
cc_library(
    name = "{lib_name}","""

_BUILD_CONTENT_CC_TARGET_SRCS = """    srcs = [{libs}],"""

_BUILD_CONTENT_CC_TARGET_OSX_LINKOPTS = """    linkopts = [
        "-F" + QT_INSTALL_LIBS,
        "-framework {lib_name}",
    ],"""

_BUILD_CONTENT_CC_TARGET_HDRS = """    hdrs = glob(["{{HEADERS_PREFIX}}/{lib_name}/**".format(HEADERS_PREFIX = HEADERS_PREFIX)], allow_empty = True),
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
qt_toolchain(
    name = "qt_unix",
    balsam = ":{EXTRA_TOOLS_PREFIX}/balsam".format(EXTRA_TOOLS_PREFIX = EXTRA_TOOLS_PREFIX),
    metatypes = METATYPES,
    moc = ":{TOOLS_PREFIX}/moc".format(TOOLS_PREFIX = TOOLS_PREFIX),
    qmltyperegistrar = ":{TOOLS_PREFIX}/qmltyperegistrar".format(TOOLS_PREFIX = TOOLS_PREFIX),
    rcc = ":{TOOLS_PREFIX}/rcc".format(TOOLS_PREFIX = TOOLS_PREFIX),
    uic = ":{TOOLS_PREFIX}/uic".format(TOOLS_PREFIX = TOOLS_PREFIX),
    headers = ":all_headers",
    qtconf = __QTCONF_VALUES__,
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
    toolchain_type = "@rules_qt//qt:toolchain_type",
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
    toolchain_type = "@rules_qt//qt:toolchain_type",
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
    toolchain_type = "@rules_qt//qt:toolchain_type",
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
    """Helper function to fill up qtconf convenience struct."""
    args = list()
    args.append("{qt_dir}/bin/qmake".format(qt_dir = qt_dir))
    args.append("-query")
    result = repository_ctx.execute(args)

    if result.return_code != 0:
        fail(result.stderr)

    qtconf = dict()
    for line in result.stdout.splitlines():
        key_value_pair = line.split(":", 1)
        qtconf[key_value_pair[0]] = key_value_pair[1]

    qt_major, qt_minor, _ = version_triplet(qtconf["QT_VERSION"])
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
        QT_QML_PATH = original_vars.QT_INSTALL_QML,
        QT_PLUGIN_PATH = original_vars.QT_INSTALL_PLUGINS,
        QT_QPA_PLATFORM_PLUGIN_PATH = "{plugins}/platforms".format(plugins = original_vars.QT_INSTALL_PLUGINS),
    )

    return struct(
        major = qt_major,
        minor = qt_minor,
        is_qt6 = qt_major == 6,
        lib_prefix = "libQt{major_version}".format(major_version = qt_major),
        qmake_query_vars = qtconf,
        original_vars = original_vars,
        extra_vars = extra_vars,
    )

def _struct_to_list(s):
    """Helper function that converts given struct `s` to a key-value list."""
    return ["{key}=\"{value}\"".format(key = key, value = value) for key, value in structs.to_dict(s).items()]

def _dict_to_list(d):
    """Helper function that converts given dict `d` to a key-value list."""
    return ["{key}=\"{value}\"".format(key = key, value = d[key]) for key in sorted(d.keys())]

def _build_metatypes_map(repository_ctx, qtconf, qt_libs_context):
    """Scans metatypes directory and maps Qt module target names to their metatype files."""
    metatypes_dir = repository_ctx.path("{}/metatypes".format(qtconf.extra_vars.LIBS_PREFIX))
    if not metatypes_dir.exists:
        # buildifier: disable=print
        print("WARNING: Qt metatypes directory not found at '{}'. QML type registration may not work.".format(metatypes_dir))
        return {}
    metatype_files = [f for f in metatypes_dir.readdir() if str(f).endswith("_metatypes.json")]

    # Build a lookup set of basenames for O(1) matching.
    basenames = {f.basename: f for f in metatype_files}

    result = {}
    for lib_name in qt_libs_context.keys():
        stem = lib_name[2:].lower()  # "QtCore" -> "core"

        # Try known naming conventions in priority order:
        #   qt6<stem>_metatypes.json       (Qt6 source/homebrew)
        #   qt6<stem>_none_metatypes.json  (Qt6 Debian/Ubuntu apt)
        #   qt5<stem>_metatypes.json       (Qt5 Linux apt)
        #   qt<stem>_metatypes.json        (Qt5 source)
        #   <stem>_metatypes.json          (Qt5 homebrew)
        candidates = [
            "qt{}{}_metatypes.json".format(qtconf.major, stem),
            "qt{}{}_none_metatypes.json".format(qtconf.major, stem),
            "qt{}_metatypes.json".format(stem),
            "{}_metatypes.json".format(stem),
        ]
        for candidate in candidates:
            if candidate in basenames:
                result[lib_name] = "{}/metatypes/{}".format(qtconf.extra_vars.LIBS_PREFIX, candidate)
                break

    if not result:
        # buildifier: disable=print
        print("WARNING: No metatypes matched any Qt module in '{}'. QML type registration may not work.".format(metatypes_dir))
    return result

def _write_qtconf(repository_ctx, qtconf, qt_libs_context):
    """Helper function to store `qtconf` struct and metatypes map into `qtconf.bzl`."""
    metatypes_map = _build_metatypes_map(repository_ctx, qtconf, qt_libs_context)

    qtconf_content = list()
    qtconf_content.append("# qmake generated variables")
    qtconf_content.extend(_dict_to_list(qtconf.qmake_query_vars))
    qtconf_content.append("# Custom prefixes")
    qtconf_content.extend(_struct_to_list(qtconf.extra_vars))
    qtconf_content.append("# Metatypes map")
    if metatypes_map:
        entries = "\n".join(["    \"{}\": \"{}\",".format(k, metatypes_map[k]) for k in sorted(metatypes_map.keys())])
        qtconf_content.append("METATYPES = {\n" + entries + "\n}")
    else:
        qtconf_content.append("METATYPES = {}")
    repository_ctx.file("qtconf.bzl", "\n".join(qtconf_content))

def _try_create_symlink(repository_ctx, target, link_name):
    """Helper function that attempts to create a symlink if it doesn't already exist."""
    target_path = repository_ctx.path(target)
    symlink = repository_ctx.path("{prefix}/{basename}".format(
        prefix = link_name,
        basename = target_path.basename,
    ))

    # Avoid creating self-referential links when Qt reports relative paths
    # (for example QT_INSTALL_LIBS=lib), which would produce loops like lib/metatypes -> lib/metatypes.
    if str(target_path) == str(symlink):
        return

    # Keep existing files/directories intact. This mirrors the original behavior
    # and avoids mutating source paths when link destinations are traversed again.
    if symlink.exists:
        return

    repository_ctx.symlink(target_path, symlink)

def _create_tools_symlinks(repository_ctx, qtconf):
    """Helper function that creates symlinks for Qt's tools."""
    path_tuples = [
        (qtconf.original_vars.QT_INSTALL_BINS, qtconf.extra_vars.EXTRA_TOOLS_PREFIX),
        (qtconf.original_vars.QT_INSTALL_LIBEXECS, qtconf.extra_vars.TOOLS_PREFIX),
    ]
    for source_path, destination_path in path_tuples:
        source_folder = repository_ctx.path(source_path)
        if not source_folder.exists:
            continue
        for path in source_folder.readdir():
            if path.basename in repository_ctx.attr._required_tools:
                _try_create_symlink(repository_ctx, path, destination_path)

def _ensure_required_tools(repository_ctx, qtconf):
    """Ensures all required Qt tools are present in the generated repository.

    If a tool is missing in a host Qt installation (common for minimal/source builds),
    create a small placeholder executable so toolchain analysis still succeeds.
    Rules that actually invoke a missing tool will fail with a clear message.
    """

    tool_to_prefix = {
        "balsam": qtconf.extra_vars.EXTRA_TOOLS_PREFIX,
        "moc": qtconf.extra_vars.TOOLS_PREFIX,
        "qmltyperegistrar": qtconf.extra_vars.TOOLS_PREFIX,
        "rcc": qtconf.extra_vars.TOOLS_PREFIX,
        "uic": qtconf.extra_vars.TOOLS_PREFIX,
    }

    for tool in repository_ctx.attr._required_tools:
        prefix = tool_to_prefix.get(tool)
        if prefix == None:
            continue

        tool_path = repository_ctx.path("{prefix}/{tool}".format(prefix = prefix, tool = tool))
        if tool_path.exists:
            continue

        repository_ctx.file(
            tool_path,
            "#!/usr/bin/env sh\necho \"rules_qt: required Qt tool '{tool}' is unavailable in this Qt installation\" >&2\nexit 1\n".format(tool = tool),
            executable = True,
        )

def _create_data_symlinks(repository_ctx, qtconf):
    """Helper function that creates symlinks for Qt's data."""
    path_tuples = [
        (qtconf.original_vars.QT_INSTALL_DATA, qtconf.extra_vars.DATA_PREFIX),
        (qtconf.original_vars.QT_INSTALL_ARCHDATA, qtconf.extra_vars.ARCHDATA_PREFIX),
        (qtconf.original_vars.QT_INSTALL_PLUGINS, qtconf.extra_vars.PLUGINS_PREFIX),
        (qtconf.original_vars.QT_INSTALL_QML, qtconf.extra_vars.QML_PREFIX),
    ]
    for source_path, destination_path in path_tuples:
        # QT_INSTALL_DATA / QT_INSTALL_ARCHDATA can resolve to the install prefix itself (destination ".").
        # Linking the whole prefix pulls in source-install self-referential symlinks and breaks globbing.
        if destination_path == ".":
            continue

        source = repository_ctx.path(source_path)
        if not source.exists:
            continue
        for path in source.readdir():
            # Skip dangling entries (e.g. broken self-referential symlinks in host Qt installs).
            if not path.exists:
                continue
            _try_create_symlink(repository_ctx, path, destination_path)

def _create_metatypes_symlink(repository_ctx, qtconf):
    """Helper function that creates symlinks for Qt's metatypes."""
    candidates = [
        repository_ctx.path("{prefix}/metatypes".format(prefix = qtconf.original_vars.QT_INSTALL_LIBS)),
        repository_ctx.path("{prefix}/metatypes".format(prefix = qtconf.original_vars.QT_INSTALL_ARCHDATA)),
    ]
    for path in candidates:
        if path.exists:
            _try_create_symlink(repository_ctx, path, qtconf.extra_vars.LIBS_PREFIX)
            return

def _create_headers_symlinks(repository_ctx, qtconf):
    """Helper function that creates symlinks for Qt's headers."""
    result = dict()

    for path in repository_ctx.path(qtconf.original_vars.QT_INSTALL_HEADERS).readdir():
        if not path.basename.startswith("Qt"):
            continue

        if not path.exists:
            continue

        _try_create_symlink(repository_ctx, path, qtconf.extra_vars.HEADERS_PREFIX)

        result[path.basename] = _QtLibsContext(
            original_path = path,
            libs = list(),
            has_headers = True,
            is_osx_framework = False,
            deps = list(),
        )

    # Homebrew Qt on macOS can install module headers under framework bundles,
    # for example: <QT_INSTALL_LIBS>/QtCore.framework/Headers.
    frameworks = repository_ctx.path(qtconf.original_vars.QT_INSTALL_LIBS)
    if frameworks.exists:
        for path in frameworks.readdir():
            if not path.basename.endswith(".framework"):
                continue

            lib_name = path.basename.replace(".framework", "")
            if not lib_name.startswith("Qt"):
                continue

            framework_headers = repository_ctx.path("{framework}/Headers".format(framework = path))
            if not framework_headers.exists:
                continue

            framework_headers_link = repository_ctx.path("{prefix}/{lib_name}".format(
                prefix = qtconf.extra_vars.HEADERS_PREFIX,
                lib_name = lib_name,
            ))
            if not framework_headers_link.exists:
                repository_ctx.symlink(framework_headers, framework_headers_link)

            if lib_name not in result:
                result[lib_name] = _QtLibsContext(
                    original_path = framework_headers,
                    libs = list(),
                    has_headers = True,
                    is_osx_framework = True,
                    deps = list(),
                )

    return result

def _create_libs_symlinks(repository_ctx, qt_libs_context, qtconf):
    """Helper function that creates symlinks for Qt's libs."""
    for path in repository_ctx.path(qtconf.original_vars.QT_INSTALL_LIBS).readdir():
        # skip non-qt files
        is_qt = path.basename.startswith(qtconf.lib_prefix) or path.basename.startswith("Qt")

        # skip non lib files
        is_osx_framework = path.basename.endswith(".framework")
        is_linux_so = ".so" in path.basename
        is_macos_dylib = path.basename.endswith(".dylib")
        is_lib = is_osx_framework or is_linux_so or is_macos_dylib

        if not is_qt or not is_lib:
            continue

        if not path.exists:
            continue

        # find out which other qt modules this one depends on
        qt_deps = []
        if is_linux_so and path.basename.endswith(".so"):
            qt_deps = _find_linux_lib_deps(repository_ctx, path, qtconf.lib_prefix)
        elif is_osx_framework or is_macos_dylib:
            qt_deps = _find_macos_lib_deps(repository_ctx, path, qtconf.lib_prefix)

        _try_create_symlink(repository_ctx, path, qtconf.extra_vars.LIBS_PREFIX)

        lib_name = _create_lib_name(path.basename, qtconf.lib_prefix)

        if lib_name in qt_libs_context:
            qt_lib_context = qt_libs_context[lib_name]
            qt_lib_context.libs.append(path.basename)
            qt_libs_context[lib_name] = _QtLibsContext(
                original_path = qt_lib_context.original_path,
                libs = qt_lib_context.libs,
                has_headers = qt_lib_context.has_headers,
                is_osx_framework = is_osx_framework,
                deps = unique(qt_lib_context.deps + qt_deps),
            )
        else:
            qt_libs_context[lib_name] = _QtLibsContext(
                original_path = path,
                libs = [path.basename],
                has_headers = False,
                is_osx_framework = is_osx_framework,
                deps = qt_deps,
            )

    return qt_libs_context

def _create_lib_name(raw_lib_name, lib_prefix):
    """Helper function that produces a name for a generated library from the raw basename of a library file.
    For example, `libQt6SomeLib.so.6` becomes `QtSomeLib`."""
    name_only = raw_lib_name.split(".")[0]
    return name_only.replace(lib_prefix, "Qt")

def _find_linux_lib_deps(repository_ctx, path, lib_prefix):
    """Analyzes a Qt shared library using `ldd` and extracts the names of its dependencies on other Qt libraries.
    Keep in mind all linked libraries are added as dependencies, even if they are optional in runtime."""
    result = repository_ctx.execute(["ldd", path])
    if result.return_code != 0:
        fail(result.stderr)

    linked_libs = [_extract_lib_from_ldd_line(line) for line in result.stdout.splitlines()]
    linked_qt_libs = [lib for lib in linked_libs if lib.startswith(lib_prefix)]
    qt_dep_names = unique([_create_lib_name(lib, lib_prefix) for lib in linked_qt_libs])

    return qt_dep_names

def _extract_lib_from_ldd_line(ldd_line):
    """Processes a line from the output of `ldd` and returns the plain name of the linked library.
    For example, one of the lines output by ldd could be this:
        `libgpg-error.so.0 => /usr/lib/libgpg-error.so.0 (0x00007f2da3691000)`
    And the output from this function would be:
        `libgpg-error`
    """
    so_basename = ldd_line.strip().split(" ")[0]
    lib_name = so_basename.split(".")[0]

    return lib_name

def _find_macos_lib_deps(repository_ctx, path, lib_prefix):
    """Analyzes a Qt library using `otool -L` and extracts the names of its dependencies on other Qt libraries."""
    target = path
    if str(path).endswith(".framework"):
        # For frameworks, otool needs the actual binary inside
        framework_name = path.basename.replace(".framework", "")
        target = repository_ctx.path("{}/{}".format(path, framework_name))
    result = repository_ctx.execute(["otool", "-L", target])
    if result.return_code != 0:
        # buildifier: disable=print
        print("rules_qt: otool -L failed for {}: {}".format(target, result.stderr))
        return []

    # Skip the first line (the library itself)
    linked_libs = [_extract_lib_from_otool_line(line) for line in result.stdout.splitlines()[1:]]
    linked_qt_libs = [lib for lib in linked_libs if lib.startswith(lib_prefix) or lib.startswith("Qt")]

    # otool -L includes the library's own install name (LC_ID_DYLIB);
    # filter it out to avoid self-dependency cycles.
    if str(path).endswith(".framework"):
        own_name = _create_lib_name(path.basename.replace(".framework", ""), lib_prefix)
    else:
        own_name = _create_lib_name(path.basename, lib_prefix)
    qt_dep_names = unique([_create_lib_name(lib, lib_prefix) for lib in linked_qt_libs if _create_lib_name(lib, lib_prefix) != own_name])

    return qt_dep_names

def _extract_lib_from_otool_line(otool_line):
    """Processes a line from the output of `otool -L` and returns the plain library name.
    Example otool line:
        `@rpath/QtCore.framework/Versions/A/QtCore (compatibility version 6.0.0, current version 6.11.0)`
    Returns: `QtCore`
    """
    path_part = otool_line.strip().split(" (")[0].strip()
    basename = path_part.split("/")[-1]
    lib_name = basename.split(".")[0]
    return lib_name

def _join_libs(libs):
    """Helper function that consolidates `libs` list in a string."""
    return ",".join(["\"{{LIBS_PREFIX}}/{lib}\".format(LIBS_PREFIX = LIBS_PREFIX)".format(lib = lib) for lib in libs])

def _join_deps(deps):
    """Helper function that consolidates `deps` list in a string."""
    return ",".join(["\"{dep}\"".format(dep = dep) for dep in deps])

def _join_includes(qtconf, libs):
    """Helper function that consolidates `includes` list in a string."""
    return ",".join(["\"{headers_prefix}/{lib}\"".format(headers_prefix = qtconf.extra_vars.HEADERS_PREFIX, lib = lib) for lib in libs])

def _join_qtconf_values(qtconf):
    """Helper function that renders Qt config values as a BUILD-compatible dictionary literal."""
    values = dict(qtconf.qmake_query_vars)
    values.update(structs.to_dict(qtconf.extra_vars))

    # Convert path objects and ensure deterministic order.
    entries = ["\"{key}\": \"{value}\"".format(key = key, value = str(values[key])) for key in sorted(values.keys())]
    return "{{{entries}}}".format(entries = ", ".join(entries))

def _clean_generated_paths(repository_ctx, qtconf):
    """Removes generated symlink trees before re-materialization."""

    paths_to_clear = [
        qtconf.extra_vars.EXTRA_TOOLS_PREFIX,
        qtconf.extra_vars.TOOLS_PREFIX,
        qtconf.extra_vars.LIBS_PREFIX,
        qtconf.extra_vars.HEADERS_PREFIX,
        qtconf.extra_vars.DATA_PREFIX,
        qtconf.extra_vars.ARCHDATA_PREFIX,
        qtconf.extra_vars.PLUGINS_PREFIX,
        qtconf.extra_vars.QML_PREFIX,
    ]

    for prefix in paths_to_clear:
        if prefix in ["", "."]:
            continue

        path = repository_ctx.path(prefix)
        if path.exists:
            repository_ctx.delete(path)

def materialize_qt_repo(repository_ctx, qt_dir):
    """Repository rule helper function that materializes a Qt SDK in Bazel format."""
    qtconf = _build_qtconf(repository_ctx, qt_dir)

    _clean_generated_paths(repository_ctx, qtconf)

    # buildifier: disable=print
    print("Qt {QT_VERSION} installed in {QT_INSTALL_PREFIX} will be used.".format(
        QT_VERSION = qtconf.original_vars.QT_VERSION,
        QT_INSTALL_PREFIX = qtconf.original_vars.QT_INSTALL_PREFIX,
    ))

    content = list()
    content.append(_BUILD_CONTENT_PROLOGUE)

    # create symlinks to make Bazel aware of relevant files
    _create_tools_symlinks(repository_ctx, qtconf)
    _ensure_required_tools(repository_ctx, qtconf)
    _create_data_symlinks(repository_ctx, qtconf)
    _create_metatypes_symlink(repository_ctx, qtconf)

    qt_libs_context = _create_headers_symlinks(repository_ctx, qtconf)
    qt_libs_context = _create_libs_symlinks(repository_ctx, qt_libs_context, qtconf)

    _write_qtconf(repository_ctx, qtconf, qt_libs_context)

    # add QtQmlIntegration for Qt6.3+ when QML modules are present
    if qtconf.major == 6 and qtconf.minor >= 3 and "QtQml" in qt_libs_context and "QtQmlIntegration" in qt_libs_context:
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
    content.append(_BUILD_CONTENT_CC_TARGET_ALL_HEADERS.format(includes = _join_includes(qtconf, sorted(qt_libs_context.keys()))))
    content.append(_BUILD_CONTENT_EPILOGUE.replace("__QTCONF_VALUES__", _join_qtconf_values(qtconf)))

    repository_ctx.file("BUILD.bazel", "\n".join(content))

def _resolve_path(repository_ctx):
    """Resolves the Qt installation path from either `path` or `paths` attribute."""
    path = repository_ctx.attr.path
    paths = repository_ctx.attr.paths
    if path and paths:
        fail("qt_local_repo: specify either 'path' or 'paths', not both")
    if not path and not paths:
        fail("qt_local_repo: either 'path' or 'paths' must be specified")
    if path:
        return path

    os_name = repository_ctx.os.name.lower()
    os_arch = repository_ctx.os.arch
    if "mac" in os_name or "darwin" in os_name:
        platform_os = "macos"
    elif "linux" in os_name:
        platform_os = "linux"
    else:
        platform_os = os_name

    # Normalize arch names
    if os_arch == "amd64" or os_arch == "x86_64":
        platform_arch = "x86_64"
    elif os_arch == "aarch64" or os_arch == "arm64":
        platform_arch = "arm64"
    else:
        platform_arch = os_arch

    platform_key = "{}-{}".format(platform_os, platform_arch)

    if platform_key in paths:
        return paths[platform_key]

    # Try OS-only fallback
    if platform_os in paths:
        return paths[platform_os]

    fail("qt_local_repo: no path configured for platform '{key}'. Available: {keys}".format(
        key = platform_key,
        keys = ", ".join(sorted(paths.keys())),
    ))

def _qt_local_repo_impl(repository_ctx):
    """Repository rule's implementation function."""
    materialize_qt_repo(repository_ctx, _resolve_path(repository_ctx))

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

In `MODULE.bazel`
```
qt = use_extension("@rules_qt//qt:extensions.bzl", "qt")

# Single-platform (backward compatible):
qt.local_repo(
    name = "qt6_local",
    path = "/opt/homebrew/opt/qt",
)

# Multi-platform:
qt.local_repo(
    name = "qt6_local",
    paths = {
        "linux-x86_64": "/usr/lib/qt6",
        "macos-arm64": "/opt/homebrew/opt/qt",
    },
)

qt.active_sdk(name = "qt", repo = "qt6_local")
use_repo(qt, "qt")
```

Switch active local SDK by changing `qt.active_sdk(..., repo = ...)`.

**qtconf.bzl**
`BUILD`
```
load("@qt//:qtconf.bzl", "QT_VERSION")
```
""",
    attrs = {
        "path": attr.string(doc = """
The path to locally installed Qt's folder where `qmake` is located, usually it is `bin` folder.
Use this for single-platform setups. For multi-platform, use `paths` instead.
"""),
        "paths": attr.string_dict(doc = """
Platform-keyed paths to locally installed Qt. Keys are `<os>-<arch>` strings,
e.g. `{"linux-x86_64": "/usr/lib/qt6", "macos-arm64": "/opt/homebrew/opt/qt"}`.
OS-only keys (e.g. `"linux"`) are also accepted as fallbacks.
Exactly one of `path` or `paths` must be specified.
"""),
        "_required_tools": attr.string_list(default = ["moc", "rcc", "uic", "qmltyperegistrar", "balsam"]),
    },
    local = True,
)
