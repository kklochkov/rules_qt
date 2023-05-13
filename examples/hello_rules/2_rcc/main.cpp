#include <QtCore/QDebug>
#include <QtCore/QFile>

int main()
{
  QFile file(":/text.txt");
  if (!file.open(QIODevice::ReadOnly))
  {
    return EXIT_FAILURE;
  }
  qDebug() << file.readAll();
  return EXIT_SUCCESS;
}
