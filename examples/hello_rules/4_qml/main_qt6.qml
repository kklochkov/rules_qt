import QtQuick
import QtQuick.Controls
import TextProvider

Rectangle {
    color: "lightgray"

    TextProvider {
      id: text_provider
      qt_version: QT_VERSION
    }

    Button {
      id: hello_button
      anchors.centerIn: parent
      text: text_provider.text
      onClicked: Qt.quit()
    }
}
