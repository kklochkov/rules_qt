#include <QtCore/QObject>

class ExternalObject : public QObject
{
  Q_OBJECT
public:
  explicit ExternalObject(QObject* parent = nullptr);

signals:
  void close_after(const int ms);

public slots:
  void set_close_timeout_ms(const int ms);
};
