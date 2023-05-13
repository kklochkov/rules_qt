<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Providers to exchange information between Qt's rules.

<a id="MocInfo"></a>

## MocInfo

<pre>
MocInfo(<a href="#MocInfo-headers">headers</a>, <a href="#MocInfo-jsons">jsons</a>)
</pre>



**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="MocInfo-headers"></a>headers |  A list of headers required by <code>moc</code>.    |
| <a id="MocInfo-jsons"></a>jsons |  A list of generated metatype information in <code>json</code> format. Consumed by [qt_qml_cc_module](docs.md#qt_qml_cc_module).    |


<a id="QrcInfo"></a>

## QrcInfo

<pre>
QrcInfo(<a href="#QrcInfo-data">data</a>, <a href="#QrcInfo-qrcs">qrcs</a>)
</pre>



**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="QrcInfo-data"></a>data |  A list of resources transitively required by [qt_cc_rcc](docs.md#qt_cc_rcc).    |
| <a id="QrcInfo-qrcs"></a>qrcs |  A list of available or generated <code>qrc</code> files by [qt_qrc](docs.md#qt_qrc) rule.    |


<a id="version_triplet"></a>

## version_triplet

<pre>
version_triplet(<a href="#version_triplet-version">version</a>)
</pre>

Helper function to convert given string `version` to a triplet of integers representing major, minor and patch version.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="version_triplet-version"></a>version |  A string that contains the version triplet.   |  none |


