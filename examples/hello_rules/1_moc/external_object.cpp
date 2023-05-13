#include "external_object.h"

ExternalObject::ExternalObject(QObject* parent) : QObject(parent)
{
}

void ExternalObject::set_close_timeout_ms(const int ms)
{
  emit close_after(ms);
}
