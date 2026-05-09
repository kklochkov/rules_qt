<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public re-exports of Qt rule providers.

These providers are used to exchange information between Qt's rules.
Load them via:

```python
load("@rules_qt//qt:providers.bzl", "MocInfo", "QrcInfo")
```

<a id="MocInfo"></a>

## MocInfo

<pre>
load("@rules_qt//qt:providers.bzl", "MocInfo")

MocInfo(<a href="#MocInfo-headers">headers</a>, <a href="#MocInfo-jsons">jsons</a>)
</pre>

**FIELDS**

| Name  | Description |
| :------------- | :------------- |
| <a id="MocInfo-headers"></a>headers |  A list of headers required by `moc`.    |
| <a id="MocInfo-jsons"></a>jsons |  A list of generated metatype information in `json` format. Consumed by [qt_qml_cc_module](docs.md#qt_qml_cc_module).    |


<a id="QrcInfo"></a>

## QrcInfo

<pre>
load("@rules_qt//qt:providers.bzl", "QrcInfo")

QrcInfo(<a href="#QrcInfo-data">data</a>, <a href="#QrcInfo-qrcs">qrcs</a>)
</pre>

**FIELDS**

| Name  | Description |
| :------------- | :------------- |
| <a id="QrcInfo-data"></a>data |  A list of resources transitively required by [qt_cc_rcc](docs.md#qt_cc_rcc).    |
| <a id="QrcInfo-qrcs"></a>qrcs |  A list of available or generated `qrc` files by [qt_qrc](docs.md#qt_qrc) rule.    |


