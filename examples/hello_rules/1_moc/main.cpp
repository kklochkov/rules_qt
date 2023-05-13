#include "external_object.h"

#include <QtCore/QCoreApplication>
#include <QtCore/QTimer>

class LocalObject : public QObject
{
  Q_OBJECT
public:
  explicit LocalObject(QObject* parnet = nullptr) : QObject(parnet) {}

signals:
  void quit();

public slots:
  void close_after(const int ms) { QTimer::singleShot(ms, this, &LocalObject::quit); }
};

int main(int argc, char* argv[])
{
  QCoreApplication app(argc, argv);

  ExternalObject external_object;
  LocalObject local_object;

  QObject::connect(&external_object, &ExternalObject::close_after, &local_object, &LocalObject::close_after);
  QObject::connect(&local_object, &LocalObject::quit, &app, &QCoreApplication::quit);

  external_object.set_close_timeout_ms(1000);

  return app.exec();
}

#include "main.moc"
