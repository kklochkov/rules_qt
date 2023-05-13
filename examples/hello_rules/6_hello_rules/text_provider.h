#include <QtCore/QObject>
#include <qqml.h>

class TextProvider : public QObject
{
  Q_OBJECT
  QML_ELEMENT

  Q_PROPERTY(QString qt_version READ get_qt_version WRITE set_qt_version NOTIFY qt_version_changed)
  Q_PROPERTY(QString text READ get_text NOTIFY qt_version_changed)
public:
  explicit TextProvider(QObject* parent = nullptr);

  void set_qt_version(const QString& version);
  QString get_qt_version() const { return version_; }

  QString get_text() const;

signals:
  void qt_version_changed();

private:
  QString version_;
};
