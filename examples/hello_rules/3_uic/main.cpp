#include "ui_widget.h"

#include <QtWidgets/QApplication>

int main(int argc, char* argv[])
{
  QApplication app(argc, argv);

  const QString qt_version(qgetenv("QT_VERSION"));

  Ui::Form ui;
  QWidget widget;
  ui.setupUi(&widget);
  ui.pushButton->setText(qt_version + ui.pushButton->text());
  QObject::connect(ui.pushButton, &QPushButton::clicked, &app, &QApplication::quit);
  widget.show();

  return app.exec();
}
