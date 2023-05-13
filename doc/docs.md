<!-- Generated with Stardoc: http://skydoc.bazel.build -->

A set of convinience macros for using Qt's rules with Bazel.

<a id="qt_balsam"></a>

## qt_balsam

<pre>
qt_balsam(<a href="#qt_balsam-name">name</a>, <a href="#qt_balsam-data">data</a>, <a href="#qt_balsam-env">env</a>, <a href="#qt_balsam-model">model</a>)
</pre>


Invokes `balsam` to generate optimized 3D for use with `QtQuick3d`.

The generated model can be used in two way:
- as a runtime dependency,
by depending on it in `cc_binary`'s `data` attribute
- as a compile time dependency. The rule provides [QrcInfo](providers-doc.md#QrcInfo) which then can be used with [qt_cc_rcc](#qt_cc_rcc).


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="qt_balsam-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="qt_balsam-data"></a>data |  A list of resources used by a 3D model.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="qt_balsam-env"></a>env |  Additional environment variables to be passed to the <code>balsam</code> process. For Qt6 it might be required to pass <code>DISPLAY=:0</code> to prevent the process crashing on Linux.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional | <code>{"DISPLAY": ":0"}</code> |
| <a id="qt_balsam-model"></a>model |  A model to be converted to optimized format for QtQuick3d usage.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="qt_cc_moc"></a>

## qt_cc_moc

<pre>
qt_cc_moc(<a href="#qt_cc_moc-name">name</a>, <a href="#qt_cc_moc-hdrs">hdrs</a>)
</pre>


Invokes `moc` on a given set of headers and exposes generated (`moc`'ed) C++ sources
to be further used in downstream `cc_*` rules.

Besides C++ sources, the rules exposes metatypes info in `json` format via [MocInfo](providers-docs.md#MocInfo).
These are required to properly register C++ QtQml types when using the [qt_qml_cc_module](#qt_qml_cc_module).

Supports both [Qt5](https://doc.qt.io/qt-5/qtqml-cppintegration-definetypes.html) and [Qt6](https://doc.qt.io/qt-6.4/qtqml-cppintegration-definetypes.html).


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="qt_cc_moc-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="qt_cc_moc-hdrs"></a>hdrs |  A list of C++ headers that needs to be <code>moc</code>'ed.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |


<a id="qt_cc_moc_import"></a>

## qt_cc_moc_import

<pre>
qt_cc_moc_import(<a href="#qt_cc_moc_import-name">name</a>, <a href="#qt_cc_moc_import-srcs">srcs</a>)
</pre>


Invokes `moc` on a given set of sources and exposes generated (`moc`'ed) C++ sources
to be further used in downstream `cc_*` rules.

See https://doc.qt.io/qt-5/moc.html#writing-make-rules-for-invoking-moc for more details.

The quote from the official docs:
```
For Q_OBJECT class declarations in implementation (.cpp) files, we suggest a makefile rule like this:

foo.o: foo.moc

foo.moc: foo.cpp
        moc $(DEFINES) $(INCPATH) -i $&lt; -o $@

This guarantees that make will run the moc before it compiles foo.cpp. You can then put

#include "foo.moc"

at the end of foo.cpp, where all the classes declared in that file are fully known.
```

## NOTE

The rule uses `CcInfo` with `compilation_context` filled in to propagate `[generated_name].moc` (which is an implementation C++ file),
because `cc_*`'s `srcs` attribute has a fixed set of supported file extensions.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="qt_cc_moc_import-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="qt_cc_moc_import-srcs"></a>srcs |  A list of C++ sources that needs to be <code>moc</code>'ed.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |


<a id="qt_cc_rcc"></a>

## qt_cc_rcc

<pre>
qt_cc_rcc(<a href="#qt_cc_rcc-name">name</a>, <a href="#qt_cc_rcc-srcs">srcs</a>)
</pre>


The rule generates C++ sources based on information provided via [QrcInfo](providers-docs.md#QrcInfo) mandatory provider.

As of now [qt_qrc](#qt_qrc) and [qt_balsam](#qt_balsam) rules use `QrcInfo` provider.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="qt_cc_rcc-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="qt_cc_rcc-srcs"></a>srcs |  A list of targets that provide <code>QrcInfo</code>.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |


<a id="qt_cc_uic"></a>

## qt_cc_uic

<pre>
qt_cc_uic(<a href="#qt_cc_uic-name">name</a>, <a href="#qt_cc_uic-srcs">srcs</a>)
</pre>


Invokes `uic` on a given set of UI forms and exposes generated C++ headers
to be further used in downstream `cc_*` rules as compile time dependency,
i.e. to the `deps` attribute of `cc_*` riles.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="qt_cc_uic-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="qt_cc_uic-srcs"></a>srcs |  A list of <code>.ui</code> forms.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |


<a id="qt_qml_cc_module"></a>

## qt_qml_cc_module

<pre>
qt_qml_cc_module(<a href="#qt_qml_cc_module-name">name</a>, <a href="#qt_qml_cc_module-major_version">major_version</a>, <a href="#qt_qml_cc_module-minor_version">minor_version</a>, <a href="#qt_qml_cc_module-moc">moc</a>, <a href="#qt_qml_cc_module-module_name">module_name</a>)
</pre>


Collects metainformation, provided by [qt_cc_moc](#qt_cc_moc) via [MocInfo](providers-docs.md#MocInfo),
of available C++ QML types and generates C++ routines to register them as QML modules.

More info about QtQml C++ integration can be found here: [Qt5](https://doc.qt.io/qt-5/qtqml-cppintegration-definetypes.html)
and [Qt6](https://doc.qt.io/qt-6.4/qtqml-cppintegration-definetypes.html).
    

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="qt_qml_cc_module-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="qt_qml_cc_module-major_version"></a>major_version |  Major version of QML module.   | Integer | optional | <code>1</code> |
| <a id="qt_qml_cc_module-minor_version"></a>minor_version |  Major version of QML module.   | Integer | optional | <code>0</code> |
| <a id="qt_qml_cc_module-moc"></a>moc |  A [qt_cc_moc](#qt_cc_moc) target that provides [MocInfo](providers-docs.md#MocInfo)   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="qt_qml_cc_module-module_name"></a>module_name |  A name of a module under which it will be accessible in QML.   | String | required |  |


<a id="qt_qrc"></a>

## qt_qrc

<pre>
qt_qrc(<a href="#qt_qrc-name">name</a>, <a href="#qt_qrc-data">data</a>, <a href="#qt_qrc-prefix">prefix</a>, <a href="#qt_qrc-srcs">srcs</a>)
</pre>


The rule either exposes already available Qt's Resources files (`qrc`) via `srcs` attribute or generates one
for further use by the resource compiler ([qt_cc_rcc](#qt_cc_rcc) rule).

The information between `qt_qrc` and `qt_cc_rcc` rules are passed via [QrcInfo](providers-docs.md#QrcInfo) provider.

In case when `srcs` has values, the rule will generate the same amount of C++ sources as a number of `qrc` files.
When the attribute is empty, the rule will first generate a `qrc` file for all resources available in `data`
attribute and place them under specified `prefix` (by default it's empty).

If both `srcs` and `prefix` attributes are provided, the `prefix` will be ignored.

The `data` attribute should have all necessary files listed for successful code generation.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="qt_qrc-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="qt_qrc-data"></a>data |  A list of resources which will be propagated to [qt_cc_rcc](#qt_cc_rcc) via [QrcInfo](providers-docs.md#QrcInfo).<br><br>In case of auto <code>qrc</code> files generation, all files listed in this attribute will be part of the generated one.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="qt_qrc-prefix"></a>prefix |  A prefix to logically group resources.<br><br>Only available for auto <code>qrc</code> file generation, i.e. when the <code>srcs</code> attribute is empty.   | String | optional | <code>""</code> |
| <a id="qt_qrc-srcs"></a>srcs |  A list of <code>qrc</code> files for will propagated to [qt_cc_rcc](#qt_cc_rcc) via [QrcInfo](providers-docs.md#QrcInfo).   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |


<a id="qt_cc_binary"></a>

## qt_cc_binary

<pre>
qt_cc_binary(<a href="#qt_cc_binary-name">name</a>, <a href="#qt_cc_binary-srcs">srcs</a>, <a href="#qt_cc_binary-deps">deps</a>, <a href="#qt_cc_binary-moc_hdrs">moc_hdrs</a>, <a href="#qt_cc_binary-moc_srcs">moc_srcs</a>, <a href="#qt_cc_binary-qrc_srcs">qrc_srcs</a>, <a href="#qt_cc_binary-ui_srcs">ui_srcs</a>, <a href="#qt_cc_binary-qml_module_name">qml_module_name</a>,
             <a href="#qt_cc_binary-qml_module_major_version">qml_module_major_version</a>, <a href="#qt_cc_binary-qml_module_minor_version">qml_module_minor_version</a>, <a href="#qt_cc_binary-qml_import_paths">qml_import_paths</a>, <a href="#qt_cc_binary-qml_modules">qml_modules</a>,
             <a href="#qt_cc_binary-kwargs">kwargs</a>)
</pre>

Convenience macro around Qt's rule and `cc_binary`.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="qt_cc_binary-name"></a>name |  A unique name for this rule.   |  none |
| <a id="qt_cc_binary-srcs"></a>srcs |  See <code>cc_binary</code>'s [srcs](https://bazel.build/reference/be/c-cpp#cc_binary.srcs) attribute.   |  <code>[]</code> |
| <a id="qt_cc_binary-deps"></a>deps |  See <code>cc_binary</code>'s [deps](https://bazel.build/reference/be/c-cpp#cc_binary.deps) attribute.   |  <code>[]</code> |
| <a id="qt_cc_binary-moc_hdrs"></a>moc_hdrs |  Headers for <code>moc</code>. See [qt_cc_moc](#qt_cc_moc) for more info.   |  <code>None</code> |
| <a id="qt_cc_binary-moc_srcs"></a>moc_srcs |  Sources for <code>moc</code>. See [qt_cc_moc_import](#qt_cc_moc_import) for more info.   |  <code>None</code> |
| <a id="qt_cc_binary-qrc_srcs"></a>qrc_srcs |  <code>qrc</code> files for <code>rcc</code>. See [qt_cc_rcc](#qt_cc_rcc) for more info.   |  <code>None</code> |
| <a id="qt_cc_binary-ui_srcs"></a>ui_srcs |  <code>ui</code> files for <code>uic</code>. See [qt_cc_uic](#qt_cc_uic) for more info.   |  <code>None</code> |
| <a id="qt_cc_binary-qml_module_name"></a>qml_module_name |  A unique name of QML module. See [qt_qml_cc_module](#qt_qml_cc_module) for more info.   |  <code>None</code> |
| <a id="qt_cc_binary-qml_module_major_version"></a>qml_module_major_version |  A major version of QML module. See [qt_qml_cc_module](#qt_qml_cc_module) for more info.   |  <code>None</code> |
| <a id="qt_cc_binary-qml_module_minor_version"></a>qml_module_minor_version |  A minor version of QML module. See [qt_qml_cc_module](#qt_qml_cc_module) for more info.   |  <code>None</code> |
| <a id="qt_cc_binary-qml_import_paths"></a>qml_import_paths |  A list of paths where the QtQml engine should look for additional imports. Sets <code>QT_PLUGIN_PATH</code>, <code>QML2_IMPORT_PATH</code> (Qt5) and <code>QML_IMPORT_PATH</code> (Qt6) environment variables.   |  <code>[]</code> |
| <a id="qt_cc_binary-qml_modules"></a>qml_modules |  A list of [qt_qml_import](#qt_qml_import) targets which will be available during runtime.   |  <code>[]</code> |
| <a id="qt_cc_binary-kwargs"></a>kwargs |  Additional arguments for <code>cc_binary</code> rule.   |  none |


<a id="qt_cc_library"></a>

## qt_cc_library

<pre>
qt_cc_library(<a href="#qt_cc_library-name">name</a>, <a href="#qt_cc_library-srcs">srcs</a>, <a href="#qt_cc_library-deps">deps</a>, <a href="#qt_cc_library-moc_hdrs">moc_hdrs</a>, <a href="#qt_cc_library-moc_srcs">moc_srcs</a>, <a href="#qt_cc_library-qrc_srcs">qrc_srcs</a>, <a href="#qt_cc_library-ui_srcs">ui_srcs</a>, <a href="#qt_cc_library-qml_module_name">qml_module_name</a>,
              <a href="#qt_cc_library-qml_module_major_version">qml_module_major_version</a>, <a href="#qt_cc_library-qml_module_minor_version">qml_module_minor_version</a>, <a href="#qt_cc_library-kwargs">kwargs</a>)
</pre>

Convenience macro around Qt's rule and `cc_library`.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="qt_cc_library-name"></a>name |  A unique name for this rule.   |  none |
| <a id="qt_cc_library-srcs"></a>srcs |  See <code>cc_library</code>'s [srcs](https://bazel.build/reference/be/c-cpp#cc_library.srcs) attribute.   |  <code>[]</code> |
| <a id="qt_cc_library-deps"></a>deps |  See <code>cc_library</code>'s [deps](https://bazel.build/reference/be/c-cpp#cc_library.deps) attribute.   |  <code>[]</code> |
| <a id="qt_cc_library-moc_hdrs"></a>moc_hdrs |  Headers for <code>moc</code>. See [qt_cc_moc](#qt_cc_moc) for more info.   |  <code>None</code> |
| <a id="qt_cc_library-moc_srcs"></a>moc_srcs |  Sources for <code>moc</code>. See [qt_cc_moc_import](#qt_cc_moc_import) for more info.   |  <code>None</code> |
| <a id="qt_cc_library-qrc_srcs"></a>qrc_srcs |  <code>qrc</code> files for <code>rcc</code>. See [qt_cc_rcc](#qt_cc_rcc) for more info.   |  <code>None</code> |
| <a id="qt_cc_library-ui_srcs"></a>ui_srcs |  <code>ui</code> files for <code>uic</code>. See [qt_cc_uic](#qt_cc_uic) for more info.   |  <code>None</code> |
| <a id="qt_cc_library-qml_module_name"></a>qml_module_name |  A unique name of QML module. See [qt_qml_cc_module](#qt_qml_cc_module) for more info.   |  <code>None</code> |
| <a id="qt_cc_library-qml_module_major_version"></a>qml_module_major_version |  A major version of QML module. See [qt_qml_cc_module](#qt_qml_cc_module) for more info.   |  <code>None</code> |
| <a id="qt_cc_library-qml_module_minor_version"></a>qml_module_minor_version |  A minor version of QML module. See [qt_qml_cc_module](#qt_qml_cc_module) for more info.   |  <code>None</code> |
| <a id="qt_cc_library-kwargs"></a>kwargs |  Additional arguments for <code>cc_library</code> rule.   |  none |


<a id="qt_qml_import"></a>

## qt_qml_import

<pre>
qt_qml_import(<a href="#qt_qml_import-name">name</a>, <a href="#qt_qml_import-srcs">srcs</a>)
</pre>

Convenience macro around `filegroup` to import QML module.

The target then can be used as runtime deps of [qt_cc_binary](#qt_cc_binary)
or compile time by using it in conjunction with [qt_qrc](#qt_qrc).

It expects that the QML module provides `qmldir`.

See [Qt 5 QtQml directory imports](https://doc.qt.io/qt-5/qtqml-syntax-directoryimports.html#directory-listing-qmldir-files)
and [Qt 6 QtQml directory imports](https://doc.qt.io/qt-6.4/qtqml-syntax-directoryimports.html#directory-listing-qmldir-files) for additional info.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="qt_qml_import-name"></a>name |  A unique name for this rule.   |  none |
| <a id="qt_qml_import-srcs"></a>srcs |  A list of files that describe a QML module.   |  none |


