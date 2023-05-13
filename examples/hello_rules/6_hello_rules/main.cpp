#include "ui_widget.h"

#include <QtQml/QQmlContext>
#include <QtQml/QQmlEngine>
#include <QtQuick/QQuickView>
#include <QtQuick3D/qquick3d.h>
#include <QtWidgets/QApplication>

#include <iostream>

class LocalObject : public QObject
{
  Q_OBJECT
public:
  explicit LocalObject(QObject* parent = nullptr) : QObject(parent) {}

signals:
  void quit();

public slots:
  void quitRequested()
  {
    std::cerr << "LocalObject: quitRequested\n";
    emit quit();
  }
};

int main(int argc, char* argv[])
{
  QApplication app(argc, argv);

  const QString qt_version(qgetenv("QT_VERSION"));
  const QString main_qml_folder(qgetenv("MAIN_QML_FOLDER"));

  QSurfaceFormat::setDefaultFormat(QQuick3D::idealSurfaceFormat());

  LocalObject object;
  QObject::connect(&object, &LocalObject::quit, &app, &QApplication::quit);

  Ui::Form ui;
  QWidget widget;
  ui.setupUi(&widget);
  ui.pushButton->setText(qt_version + ui.pushButton->text());
  QObject::connect(ui.pushButton, &QPushButton::clicked, &object, &LocalObject::quitRequested);
  widget.show();

  QQuickView view;
  view.setResizeMode(QQuickView::SizeRootObjectToView);
  view.engine()->rootContext()->setContextProperty("QT_VERSION", qt_version),
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
      view.setSource(QUrl::fromLocalFile(QString("%0/main.qml").arg(main_qml_folder)));
#else
      view.setSource(QUrl::fromLocalFile(QString("%0/main_qt6.qml").arg(main_qml_folder)));
#endif
  QObject::connect(view.engine(), &QQmlEngine::quit, &object, &LocalObject::quitRequested);
  view.show();

  return app.exec();
}

#include "main.moc"
