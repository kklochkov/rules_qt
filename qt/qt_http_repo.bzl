"""Repository rule that fetches, configures and builds Qt and makes it available in Bazel."""

load(":private/utils.bzl", "QT_REPO_INSTALL_FILE", "version_triplet")

_ModuleProvider = provider(
    doc = """
Provides information about Qt's module to be built.
""",
    fields = {
        "build_path": "The path to the shadow build folder.",
        "name": "The name of the module.",
        "srcs_path": "The path to unpacked module's sources.",
    },
)

def _fetch(repository_ctx):
    """Helper function that downloads and extracts Qt's modules."""
    modules = list()

    def _archive_stem(name):
        if name.endswith(".tar.xz"):
            return name[:-7]
        if name.endswith(".tar.gz"):
            return name[:-7]
        if name.endswith(".zip"):
            return name[:-4]
        return name

    for module, sha256 in repository_ctx.attr.modules.items():
        url = "{base_url}/{module}".format(base_url = repository_ctx.attr.base_url, module = module)
        repository_ctx.download_and_extract(url = url, output = ".", sha256 = sha256)

        folders = repository_ctx.path(".").readdir()
        module_stem = _archive_stem(module)
        extracted = list()
        for folder in folders:
            folder_name = folder.basename
            if folder_name == module_stem or folder_name.startswith(module_stem):
                extracted.append(folder)

        if len(extracted) == 1:
            folder_name = extracted[0].basename
            modules.append(_ModuleProvider(
                srcs_path = repository_ctx.path(folder_name),
                name = folder_name,
                build_path = ".build-{module}".format(module = folder_name),
            ))
            continue

        module_name = module.split("-")[0]
        for folder in folders:
            folder_name = folder.basename
            if folder_name.startswith(module_name):
                modules.append(_ModuleProvider(
                    srcs_path = repository_ctx.path(folder_name),
                    name = folder_name,
                    build_path = ".build-{module}".format(module = folder_name),
                ))

    return modules

def _execute_nproc(repository_ctx, command):
    """Helper function that executes given `command` and returns a number of available CPUs if execution was successful."""
    result = repository_ctx.execute(command)
    if result.return_code == 0:
        lines = result.stdout.splitlines()
        if len(lines) > 0:
            return max(1, int(lines[0]))
    return 1

def _get_nproc_linux(repository_ctx):
    """Helper function that returns a number of available CPUs on Linux."""
    return _execute_nproc(repository_ctx, ["nproc"])

def _get_nproc_macos(repository_ctx):
    """Helper function that returns a number of available CPUs on macOS."""
    return _execute_nproc(repository_ctx, ["sysctl", "-n", "hw.logicalcpu"])

def _patch_qt5_macos_mkspec(repository_ctx, module):
    """Patch Qt5 macOS mkspec to stop referencing removed AGL framework.

    New Xcode SDKs no longer provide AGL.framework headers. Qt 5.15's default
    mkspec still references them, which makes OpenGL detection fail early.
    """
    mac_conf = repository_ctx.path("{module}/mkspecs/common/mac.conf".format(module = module.name))
    if not mac_conf.exists:
        return

    content = repository_ctx.read(mac_conf)
    content = content.replace("/System/Library/Frameworks/AGL.framework/Headers/", "")
    content = content.replace("-framework OpenGL -framework AGL", "-framework OpenGL")
    repository_ctx.file(mac_conf, content)

def _patch_qt6_syncqt_regex(repository_ctx, module):
    """Patch Qt6 syncqt regex to support source paths with '+' characters.

    Under bzlmod external repositories, source paths contain '+' in directory
    names (for example: rules_qt++qt+qt6_src). Qt 6.11's syncqt helper uses
    CMAKE_CURRENT_SOURCE_DIR directly inside a regex, where '+' must be escaped.
    """
    helpers = repository_ctx.path("{module}/cmake/QtSyncQtHelpers.cmake".format(module = module.name))
    if not helpers.exists:
        return

    content = repository_ctx.read(helpers)
    needle = """    # Filter the generated ui_ header files and header files located in the 'doc/' subdirectory.
    list(FILTER module_headers EXCLUDE REGEX
        \"(.+/(ui_)[^/]+\\\\.h|${CMAKE_CURRENT_SOURCE_DIR}(/.+)?/doc/+\\\\.h)\")
"""
    patch = """    # Filter the generated ui_ header files and header files located in the 'doc/' subdirectory.
    # Escape regex metacharacters in source dir (notably '+' in bzlmod external paths).
    string(REGEX REPLACE \"([][+.*?^$(){}|\\\\])\" \"\\\\\\\\1\" _qt_regex_safe_current_source_dir \"${CMAKE_CURRENT_SOURCE_DIR}\")
    list(FILTER module_headers EXCLUDE REGEX
        \"(.+/(ui_)[^/]+\\\\.h|${_qt_regex_safe_current_source_dir}(/.+)?/doc/+\\\\.h)\")
"""

    if needle in content:
        repository_ctx.file(helpers, content.replace(needle, patch))

def _patch_qt6_macos_yield_builtin(repository_ctx, module):
    """Patch Qt6 qyieldcpu header for AppleClang arm64 toolchains.

    Some AppleClang/Xcode combinations report `__has_builtin(__yield)` but
    still require `<arm_acle.h>` for the symbol declaration.
    """
    header = repository_ctx.path("{module}/src/corelib/thread/qyieldcpu.h".format(module = module.name))
    if not header.exists:
        return

    content = repository_ctx.read(header)
    if "#include <arm_acle.h>" in content:
        return

    needle = "#include <QtCore/qtconfigmacros.h>\n"
    patch = """#include <QtCore/qtconfigmacros.h>

#if defined(Q_PROCESSOR_ARM) || defined(Q_PROCESSOR_ARM_64)
#  include <arm_acle.h>
#endif
"""

    if needle in content:
        repository_ctx.file(header, content.replace(needle, patch))

def _configure_and_build(repository_ctx, configure_args, toolchain, working_directory):
    """Helper function that configures, builds and installs a Qt's module."""
    result = repository_ctx.execute(
        configure_args + toolchain.configure_extra_args,
        quiet = False,
        working_directory = working_directory,
    )
    if result.return_code != 0:
        fail(result.stderr)

    result = repository_ctx.execute(
        toolchain.build_args,
        timeout = repository_ctx.attr.timeout,
        quiet = False,
        working_directory = working_directory,
    )
    if result.return_code != 0:
        fail(result.stderr)

    result = repository_ctx.execute(
        toolchain.install_args,
        quiet = False,
        environment = {
            # Force materialized install artifacts. Some environments can default
            # CMake installs to symlinks, which may produce broken/self-referential links in external repository paths.
            "CMAKE_INSTALL_MODE": "COPY",
        },
        working_directory = working_directory,
    )
    if result.return_code != 0:
        fail(result.stderr)

def _qt_version(repository_ctx, qt_base_module):
    """Helper function that retrieves Qt's version to build."""
    qmake_conf = repository_ctx.path("{module}/.qmake.conf".format(module = qt_base_module))
    cmake_conf = repository_ctx.path("{module}/.cmake.conf".format(module = qt_base_module))

    def _version_from_name(module_name):
        for token in module_name.replace("_", "-").split("-"):
            if token.count(".") != 2:
                continue
            is_version_token = True
            for i in range(len(token)):
                ch = token[i]
                if not ((ch >= "0" and ch <= "9") or ch == "."):
                    is_version_token = False
                    break
            if is_version_token:
                return version_triplet(token)
        return None

    version = None
    if qmake_conf.exists:
        for line in repository_ctx.read(qmake_conf).splitlines():
            if "MODULE_VERSION" in line:
                version = line.replace("MODULE_VERSION", "").replace("=", "").strip()
                return version_triplet(version)
    elif cmake_conf.exists:
        for line in repository_ctx.read(cmake_conf).splitlines():
            if "set(QT_REPO_MODULE_VERSION" in line:
                version = line.replace("set(QT_REPO_MODULE_VERSION", "").replace("\"", "").replace(")", "").strip()
                return version_triplet(version)

    version = _version_from_name(qt_base_module)
    if version:
        return version

    fail("Cannot determine Qt version!")

def _build_qtbase(repository_ctx, prefix, module):
    """Helper function that builds `qtbase` and returns a toolchain for building other modules."""
    configure_args = list()
    configure_args.append(repository_ctx.path("{module}/configure".format(module = module.name)))
    configure_args.append("-prefix")
    configure_args.append(prefix)
    configure_args.extend(repository_ctx.attr.configure_args)
    configure_args.append("-R")
    configure_args.append("{prefix}/lib".format(prefix = prefix))

    is_mac_os = repository_ctx.os.name.startswith("mac os")
    nproc = 1
    if repository_ctx.os.name == "linux":
        configure_args.append("-rpath")
        nproc = _get_nproc_linux(repository_ctx)
    elif is_mac_os:
        configure_args.append("-no-rpath")  # force full path in binaries, works with Qt 5 only
        nproc = _get_nproc_macos(repository_ctx)

    major, _, _ = _qt_version(repository_ctx, module.name)

    if is_mac_os and major == 5:
        _patch_qt5_macos_mkspec(repository_ctx, module)
    elif major == 6:
        _patch_qt6_syncqt_regex(repository_ctx, module)
        if is_mac_os:
            configure_args.append("-no-framework")
            _patch_qt6_macos_yield_builtin(repository_ctx, module)

    configure_module_tool = None
    configure_extra_args = list()  # only needed for Qt6, because it uses cmake to configure modules instead of qmake
    build_args = None
    install_args = None

    if major == 6:
        # Qt 6.4.x sets QT_LEAN_HEADERS=1 in .cmake.conf, which can break
        # qtbase self-builds on macOS/clang (missing QSet definitions in Core).
        # Force-disable lean headers for reliability in source builds.
        configure_extra_args.append("--")
        configure_extra_args.append("-DQT_EXTRA_INTERNAL_TARGET_DEFINES=")

        configure_module_tool = repository_ctx.path("{prefix}/bin/qt-configure-module".format(prefix = prefix))

        # https://gitlab.kitware.com/cmake/community/-/wikis/doc/cmake/RPATH-handling
        configure_extra_args.append("-DCMAKE_SKIP_BUILD_RPATH=FALSE")
        configure_extra_args.append("-DCMAKE_BUILD_WITH_INSTALL_RPATH=FALSE")
        configure_extra_args.append("-DCMAKE_INSTALL_RPATH={prefix}/lib".format(prefix = prefix))
        configure_extra_args.append("-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE")

        if is_mac_os:
            # force full path in binaries
            configure_extra_args.append("-DCMAKE_INSTALL_NAME_DIR={prefix}/lib".format(prefix = prefix))
            # Skip Xcode version check — Command Line Tools + CMake/Ninja suffice
            configure_extra_args.append("-DQT_NO_APPLE_SDK_AND_XCODE_CHECK=ON")

        build_args = list()
        build_args.append("cmake")
        build_args.append("--build")
        build_args.append(".")
        build_args.append("--parallel")
        build_args.append(str(nproc))

        install_args = list()
        install_args.append("cmake")
        install_args.append("--install")
        install_args.append(".")
    else:
        configure_module_tool = repository_ctx.path("{prefix}/bin/qmake".format(prefix = prefix))

        build_args = list()
        build_args.append("make")
        build_args.append("-j{nproc}".format(nproc = nproc))

        install_args = list()
        install_args.append("make")
        install_args.append("install")

    toolchain = struct(
        configure_module_tool = configure_module_tool,
        configure_extra_args = configure_extra_args,
        build_args = build_args,
        install_args = install_args,
    )

    _configure_and_build(
        repository_ctx,
        configure_args = configure_args,
        toolchain = toolchain,
        working_directory = module.build_path,
    )

    return toolchain

def _build_qtmodule(repository_ctx, toolchain, module):
    """Helper function to build a Qt's module."""
    args = list()
    args.append(toolchain.configure_module_tool)
    args.append(repository_ctx.path(module.name))

    _configure_and_build(
        repository_ctx,
        configure_args = args,
        toolchain = toolchain,
        working_directory = module.build_path,
    )

def _build(repository_ctx, prefix, modules):
    """Helper function to configure, build and install available Qt's modules."""
    if not modules:
        return
    first = modules[0]
    if not first.name.startswith("qtbase"):
        fail("The first module must be 'qtbase', got '{name}'. ".format(name = first.name) +
             "Re-order the modules dict so that qtbase comes first.")
    toolchain = _build_qtbase(repository_ctx, prefix, first)
    for module in modules[1:]:
        _build_qtmodule(repository_ctx, toolchain, module)

def _fixup_headers(repository_ctx, prefix):
    """Helper function to install headers in case Qt is built with the `-framework` flag on macOS."""
    include = repository_ctx.path("{prefix}/include".format(prefix = prefix))
    libs = repository_ctx.path("{prefix}/lib".format(prefix = prefix))
    for lib in libs.readdir():
        if str(lib).endswith(".framework"):
            lib_name = lib.basename.replace(".framework", "")
            headers = repository_ctx.path("{prefix}/Headers".format(prefix = lib))
            if headers.exists:
                for header in headers.readdir():
                    repository_ctx.symlink(
                        header,
                        repository_ctx.path("{include}/{lib_name}/{header}".format(
                            include = include,
                            lib_name = lib_name,
                            header = header.basename,
                        )),
                    )

def _cleanup(repository_ctx, modules):
    """Helper function to remove shadow build and source folders."""
    for module in modules:
        repository_ctx.delete(module.srcs_path)
        repository_ctx.delete(module.build_path)

def _qt_http_repo_impl(repository_ctx):
    """Repository rule's implementation function."""
    prefix = repository_ctx.path(repository_ctx.attr.prefix)
    install_marker = repository_ctx.path(QT_REPO_INSTALL_FILE)
    if install_marker.exists:
        return

    modules = _fetch(repository_ctx)
    _build(repository_ctx, prefix, modules)
    _fixup_headers(repository_ctx, prefix)
    _cleanup(repository_ctx, modules)

    repository_ctx.file(QT_REPO_INSTALL_FILE, "{prefix}".format(prefix = prefix))
    repository_ctx.file("BUILD.bazel", "")

qt_http_repo = repository_rule(
    implementation = _qt_http_repo_impl,
    doc = """
The rule downloads Qt's modules from http://download.qt.io/archive/qt/,
extracts, configures and builds them.

The configuration and building are done as per [Building Qt5 from git](https://wiki.qt.io/Building_Qt_5_from_Git)
and [Building Qt6 from git](https://wiki.qt.io/Building_Qt_6_from_Git), that means that all requirements and tools
need to be installed on a host.

The build is not hermetic, because it uses host tools.

The rule is consumed by [qt_remote_repo](qt_remote_repo-docs.md) through the bzlmod
extension flow (`qt.remote_repo(...)` + `qt.active_sdk(...)`).

**Example**

In `MODULE.bazel`
```
qt = use_extension("@rules_qt//qt:extensions.bzl", "qt")

qt.remote_repo(
    name = "qt5_remote",
    base_url = "https://download.qt.io/archive/qt/5.15/5.15.18/submodules",
    configure_args = [...],
    # @unsorted-dict-items
    # order matters
    modules = {...},
    prefix = "qt-5.15.18",
)

qt.active_sdk(name = "qt", repo = "qt5_remote")

use_repo(qt, "qt")
```

See [examples/MODULE.bazel](../examples/MODULE.bazel) for a complete example.
""",
    attrs = {
        "base_url": attr.string(
            mandatory = True,
            doc = "A base url to Qt's archives repo.",
        ),
        "configure_args": attr.string_list(
            mandatory = True,
            doc = """Qt's configure args.
`-prefix`, `-R` and `-rpath` should not be provided, because they are handled internally by the rules.
""",
        ),
        "modules": attr.string_dict(
            mandatory = True,
            doc = """A list of Qt's modules to be built.
The rules doesn't attempt to resolve dependencies in which
modules have to be built, except QtBase which always gets built first.
That means that a user of the rule, must provide correct modules order
for the build to succeed.
It is recommend to use `@unsorted-dict-items` to prevent sorting
of values in this field upon declaration.
""",
        ),
        "prefix": attr.string(
            mandatory = True,
            doc = "A prefix where Qt will be installed.",
        ),
        "timeout": attr.int(
            default = 2400,
            doc = "Build timeout in seconds for each Qt module. Increase for large modules on slow machines.",
        ),
    },
)
