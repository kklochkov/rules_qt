"""Helper rule to fetch several files from a given urls list and group them under one unified repo.

### Reasoning
The glTF repo is very big and takes time to be downloaded with `http_archive` (which is a recommended way),
`http_file` allows you to download a single file which is not very convenient for this particular case,
so that's why this rule was created.
"""

def _http_files(repository_ctx):
    content = list()
    content.append("package(default_visibility = [\"//visibility:public\"])\n")

    content.append("filegroup(")
    content.append("  name=\"{name}\",".format(name = repository_ctx.name))
    content.append("  srcs=[")

    for url, sha256 in repository_ctx.attr.urls.items():
        name = url.split("/")[-1]
        path = "files/{name}".format(name = name)
        repository_ctx.download(url = url, output = path, sha256 = sha256)
        content.append("    \"{path}\",".format(path = path))

    content.append("  ]")
    content.append(")")

    repository_ctx.file("BUILD.bazel", "\n".join(content))

http_files = repository_rule(
    implementation = _http_files,
    doc = """Helper rule to fetch several files from a given urls list and group them under one unified repo.

### Reasoning
The glTF repo is very big and takes time to be downloaded with `http_archive` (which is a recommended way),
`http_file` allows you to download a single file which is not very convenient for this particular case,
so that's why this rule was created.
""",
    attrs = {
        "urls": attr.string_dict(mandatory = True, doc = "A list of urls to download."),
    },
)
