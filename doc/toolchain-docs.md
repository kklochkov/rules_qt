<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Qt toolchain that allows building Qt/QtQuick applications with Bazel.

<a id="qt_toolchain"></a>

## qt_toolchain

<pre>
qt_toolchain(<a href="#qt_toolchain-name">name</a>, <a href="#qt_toolchain-balsam">balsam</a>, <a href="#qt_toolchain-headers">headers</a>, <a href="#qt_toolchain-metatypes">metatypes</a>, <a href="#qt_toolchain-moc">moc</a>, <a href="#qt_toolchain-qmltyperegistrar">qmltyperegistrar</a>, <a href="#qt_toolchain-rcc">rcc</a>, <a href="#qt_toolchain-uic">uic</a>)
</pre>


Implements Qt's toolchain to build Qt and QtQuick applications with Bazel.

Qt support: Qt5 and Qt6.

Testing: Qt 5.15 and Qt 6.4.

Platforms: linux and macOS.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="qt_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="qt_toolchain-balsam"></a>balsam |  The path to Qt's <code>balsam</code> tool. See [qt_balsam](docs.md#qt_balsam).   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="qt_toolchain-headers"></a>headers |  The list of Qt's headers.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="qt_toolchain-metatypes"></a>metatypes |  The list of Qt's metatypes.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="qt_toolchain-moc"></a>moc |  The path to Qt's <code>moc</code> tool. See [qt_cc_moc](docs.md#qt_cc_moc).   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="qt_toolchain-qmltyperegistrar"></a>qmltyperegistrar |  The path to Qt's <code>qmltyperegistrar</code> tool. See [qt_qml_cc_module](docs.md#qt_qml_cc_module).   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="qt_toolchain-rcc"></a>rcc |  The path to Qt's <code>rcc</code> tool. See [qt_cc_rcc](docs.md#qt_cc_rcc).   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="qt_toolchain-uic"></a>uic |  The path to Qt's <code>uic</code> tool. See [qt_cc_uic](docs.md#qt_cc_uic).   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="QtInfo"></a>

## QtInfo

<pre>
QtInfo(<a href="#QtInfo-balsam">balsam</a>, <a href="#QtInfo-headers">headers</a>, <a href="#QtInfo-metatypes">metatypes</a>, <a href="#QtInfo-moc">moc</a>, <a href="#QtInfo-qmltyperegistrar">qmltyperegistrar</a>, <a href="#QtInfo-rcc">rcc</a>, <a href="#QtInfo-uic">uic</a>)
</pre>



**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="QtInfo-balsam"></a>balsam |  The path to Qt's <code>balsam</code> tool. See [qt_balsam](docs.md#qt_balsam).    |
| <a id="QtInfo-headers"></a>headers |  The list of Qt's headers.    |
| <a id="QtInfo-metatypes"></a>metatypes |  The list of Qt's metatypes.    |
| <a id="QtInfo-moc"></a>moc |  The path to Qt's <code>moc</code> tool. See [qt_cc_moc](docs.md#qt_cc_moc).    |
| <a id="QtInfo-qmltyperegistrar"></a>qmltyperegistrar |  The path to Qt's <code>qmltyperegistrar</code> tool. See [qt_qml_cc_module](docs.md#qt_qml_cc_module).    |
| <a id="QtInfo-rcc"></a>rcc |  The path to Qt's <code>rcc</code> tool. See [qt_cc_rcc](docs.md#qt_cc_rcc).    |
| <a id="QtInfo-uic"></a>uic |  The path to Qt's <code>uic</code> tool. See [qt_cc_uic](docs.md#qt_cc_uic).    |


