#include "text_provider.h"

TextProvider::TextProvider(QObject* parent) : QObject(parent)
{
}

void TextProvider::set_qt_version(const QString& version)
{
  if (version != version_)
  {
    version_ = version;
    emit qt_version_changed();
  }
}

QString TextProvider::get_text() const
{
  return QString("%0Hello QtQuick3D from TextProvider!").arg(version_);
}
