import QtQuick
import QtQuick.Controls
import QtQuick3D
import TextProvider
import damaged_helmet

Rectangle {
    color: "lightgray"

    TextProvider {
      id: text_provider
      qt_version: QT_VERSION
    }

    Button {
      id: hello_button
      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
      }
      text: text_provider.text
      onClicked: Qt.quit()
    }

    View3D {
        id: view
        anchors {
          top: hello_button.bottom
          left: parent.left
          right: parent.right
          bottom: parent.bottom
        }

        environment: SceneEnvironment {
            clearColor: "lightgray"
            backgroundMode: SceneEnvironment.Color
        }

        PerspectiveCamera {
            position: Qt.vector3d(0, 200, 300)
            eulerRotation.x: -30
        }

        DirectionalLight {
            eulerRotation.x: -30
        }

        DamagedHelmet{
            id: damaged_helmet
            visible: true
            position: Qt.vector3d(0, 0, 0)
            scale: Qt.vector3d(60, 60, 60)
            eulerRotation.y: 90

            SequentialAnimation on eulerRotation {
                loops: Animation.Infinite
                PropertyAnimation {
                    duration: 5000
                    from: Qt.vector3d(0, 0, 0)
                    to: Qt.vector3d(360, 0, 360)
                }
            }
        }
    }
}
