import QtQuick 2.0
import QtQuick.Controls 2.2
import TextProvider 2.3

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
