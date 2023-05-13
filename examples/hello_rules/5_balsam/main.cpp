#include <QtGui/QGuiApplication>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlEngine>
#include <QtQuick/QQuickView>
#include <QtQuick3D/qquick3d.h>

int main(int argc, char* argv[])
{
  QGuiApplication app(argc, argv);

  const QString qt_version(qgetenv("QT_VERSION"));
  const QString main_qml_folder(qgetenv("MAIN_QML_FOLDER"));

  QSurfaceFormat::setDefaultFormat(QQuick3D::idealSurfaceFormat());

  QQuickView view;
  view.setResizeMode(QQuickView::SizeRootObjectToView);
  view.engine()->rootContext()->setContextProperty("QT_VERSION", qt_version),
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
      view.setSource(QUrl::fromLocalFile(QString("%0/main.qml").arg(main_qml_folder)));
#else
      view.setSource(QUrl::fromLocalFile(QString("%0/main_qt6.qml").arg(main_qml_folder)));
#endif
  QObject::connect(view.engine(), &QQmlEngine::quit, &app, &QGuiApplication ::quit);
  view.show();

  return app.exec();
}
