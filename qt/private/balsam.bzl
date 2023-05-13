"""Rules that allow to use [Qt's balsam](https://doc.qt.io/qt-5/qtquick3d-tool-balsam.html) with Bazel."""

load(":private/utils.bzl", "QT_TOOLCHAIN", "QrcInfo")

def _balsam_impl(ctx):
    toolchain = ctx.toolchains[QT_TOOLCHAIN]

    out = ctx.actions.declare_directory(ctx.attr.name)
    qmldir = ctx.actions.declare_file("{name}/qmldir".format(name = ctx.attr.name))

    # Qt's balsam doesn't create qmldir for generated model,
    # so let's create one ourselves to easy its importing.
    ctx.actions.run_shell(
        inputs = ctx.files.model + ctx.files.data,
        outputs = [out, qmldir],
        command = """
{balsam} --optimizeGraph --optimizeMeshes {model} --outputPath {out}

qmldir="{qmldir}"
files=($(ls {out}))
for file in "${{files[@]}}"
do
  ext="${{file##*.}}"
  if [ $ext == "qml" ]; then
    basename="${{file%.*}}"
    echo "module $basename" > $qmldir
    echo "$basename 1.0 $file" >> $qmldir
  fi
done
      """.format(
            balsam = toolchain.qtinfo.balsam.path,
            model = ctx.file.model.path,
            out = out.path,
            qmldir = qmldir.path,
        ),
        tools = [toolchain.qtinfo.balsam],
        env = ctx.attr.env,
    )

    # generate qrc
    qrc = ctx.actions.declare_file("{name}.qrc".format(name = ctx.attr.name))

    args = ctx.actions.args()
    args.add_all([out])

    ctx.actions.run_shell(
        inputs = [out],
        outputs = [qrc],
        command = """
qrc="{qrc}"

echo "<RCC>" > $qrc
echo "  <qresource>" >> $qrc

path="$(dirname $qrc)/"
len=${{#path}}

for file in "$@"
do
    rel_path=${{file:$len}}
    echo "    <file>$rel_path</file>" >> $qrc
done

echo "  </qresource>" >> $qrc
echo "</RCC>" >> $qrc
          """.format(qrc = qrc.path),
        arguments = [args],
    )

    data = [out, qmldir]
    return [
        DefaultInfo(files = depset(data)),
        QrcInfo(qrcs = [qrc], data = data),
    ]

balsam = rule(
    implementation = _balsam_impl,
    executable = False,
    doc = """
Invokes `balsam` to generate optimized 3D for use with `QtQuick3d`.

The generated model can be used in two way:
- as a runtime dependency,
by depending on it in `cc_binary`'s `data` attribute
- as a compile time dependency. The rule provides [QrcInfo](providers-doc.md#QrcInfo) which then can be used with [qt_cc_rcc](#qt_cc_rcc).
""",
    attrs = {
        "data": attr.label_list(
            allow_files = True,
            doc = """
A list of resources used by a 3D model.
            """,
        ),
        "env": attr.string_dict(
            default = {"DISPLAY": ":0"},
            doc = """
Additional environment variables to be passed to the `balsam` process.
For Qt6 it might be required to pass `DISPLAY=:0` to prevent the process crashing on Linux.
""",
        ),
        "model": attr.label(
            mandatory = True,
            allow_single_file = [".obj", ".dae", ".fbx", ".blend", ".gltf", ".glb"],
            doc = """
A model to be converted to optimized format for QtQuick3d usage.
""",
        ),
    },
    toolchains = [QT_TOOLCHAIN],
    provides = [DefaultInfo, QrcInfo],
)
