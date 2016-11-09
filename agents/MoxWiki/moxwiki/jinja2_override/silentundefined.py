from jinja2 import Undefined

class SilentUndefined(Undefined):

    def _fail_with_undefined_error(self, *args, **kwargs):
        return None

    def _return_new_silentundefined(self, *args, **kwargs):
        return SilentUndefined()

    def _emptystring(self):
        return u''

    __unicode__ = __str__ = _emptystring

    __call__ = __getattr__ = __getitem__ = _return_new_silentundefined