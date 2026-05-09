"""Public re-exports of Qt rule providers.

These providers are used to exchange information between Qt's rules.
Load them via:

```python
load("@rules_qt//qt:providers.bzl", "MocInfo", "QrcInfo")
```
"""

load(":private/utils.bzl", _MocInfo = "MocInfo", _QrcInfo = "QrcInfo")

MocInfo = _MocInfo
QrcInfo = _QrcInfo
