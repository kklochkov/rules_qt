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
    for module, sha256 in repository_ctx.attr.modules.items():
        url = "{base_url}/{module}".format(base_url = repository_ctx.attr.base_url, module = module)
        repository_ctx.download_and_extract(url = url, output = ".", sha256 = sha256)

        folders = repository_ctx.path(".").readdir()
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

def _get_nproc(repository_ctx):
    """Helper function that returns a number of available CPUs."""
    result = repository_ctx.execute(["nproc"])
    return int(result.stdout.splitlines()[0]) if result.return_code == 0 else 1

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
        timeout = 2400,
        quiet = False,
        working_directory = working_directory,
    )
    if result.return_code != 0:
        fail(result.stderr)

    result = repository_ctx.execute(
        toolchain.install_args,
        quiet = False,
        working_directory = working_directory,
    )
    if result.return_code != 0:
        fail(result.stderr)

def _qt_version(repository_ctx, qt_base_module):
    """Helper function that retrieves Qt's version to build."""
    qmake_conf = repository_ctx.path("{module}/.qmake.conf".format(module = qt_base_module))
    cmake_conf = repository_ctx.path("{module}/.cmake.conf".format(module = qt_base_module))

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
    if repository_ctx.os.name == "linux":
        configure_args.append("-rpath")
    elif is_mac_os:
        configure_args.append("-no-rpath")  # force full path in binaries, workis with Qt 5 only

    nproc = _get_nproc(repository_ctx)
    major, _, _ = _qt_version(repository_ctx, module.name)
    configure_module_tool = None
    configure_extra_args = list()  # only needed for Qt6, because it uses cmake to configure modules instead of qmake
    build_args = None
    install_args = None

    if major == 6:
        configure_module_tool = repository_ctx.path("{prefix}/bin/qt-configure-module".format(prefix = prefix))

        # https://gitlab.kitware.com/cmake/community/-/wikis/doc/cmake/RPATH-handling
        configure_extra_args.append("--")
        configure_extra_args.append("-DCMAKE_SKIP_BUILD_RPATH=FALSE")
        configure_extra_args.append("-DCMAKE_BUILD_WITH_INSTALL_RPATH=FALSE")
        configure_extra_args.append("-DCMAKE_INSTALL_RPATH={prefix}/lib".format(prefix = prefix))
        configure_extra_args.append("-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE")

        if is_mac_os:
            # force full path in binaries
            configure_extra_args.append("-DCMAKE_INSTALL_NAME_DIR={prefix}/lib".format(prefix = prefix))

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
    toolchain = None
    for module in modules:
        if module.name.startswith("qtbase"):
            toolchain = _build_qtbase(repository_ctx, prefix, module)
        else:
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
    if prefix.exists == True:
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

The rule is supposed to be used in conjunction with [qt_local_repo](qt_local_repo-docs.md).

**Example**

In `WORKSPACE`
```
# Qt remote repo
load("@com_github_kklochkov_rules_qt//qt:qt_http_repo.bzl", "qt_http_repo")

qt_http_repo(
    name = "qt_5.15.8",
    base_url = "https://download.qt.io/official_releases/qt/5.15/5.15.8/submodules",
    configure_args = [...],
    # @unsorted-dict-items
    # order matters
    modules = {...},
    prefix = "qt-5.15.8",
)

# Qt local repo
load("@com_github_kklochkov_rules_qt//qt:qt_local_repo.bzl", "qt_local_repo")

qt_local_repo(
    name = "qt",
    qt_http_repo = "@qt_5.15.8",
)
```

See [examples/WORKSPACE](../examples/WORKSPACE) for a complete example.
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
    },
)
