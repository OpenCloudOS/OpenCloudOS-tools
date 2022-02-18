"""Wrapper to the POSIX crypt library call and associated functionality.

Note that the ``methods`` and ``METHOD_*`` attributes are non-standard
extensions to Python 2.6, backported from 3.3"""

import _crypt
import string
from random import choice
from collections import namedtuple


_saltchars = string.ascii_letters + string.digits + './'


class _Method(namedtuple('_Method', 'name ident salt_chars total_size')):

    """Class representing a salt method per the Modular Crypt Format or the
    legacy 2-character crypt method."""

    def __repr__(self):
        return '<crypt.METHOD_%s>' % self.name



def mksalt(method=None):
    """Generate a salt for the specified method.

    If not specified, the strongest available method will be used.

    This is a non-standard extension to Python 2.6, backported from 3.3
    """
    if method is None:
        method = methods[0]
    s = '$%s$' % method.ident if method.ident else ''
    s += ''.join(choice(_saltchars) for _ in range(method.salt_chars))
    return s


def crypt(word, salt=None):
    """Return a string representing the one-way hash of a password, with a salt
    prepended.

    If ``salt`` is not specified or is ``None``, the strongest
    available method will be selected and a salt generated.  Otherwise,
    ``salt`` may be one of the ``crypt.METHOD_*`` values, or a string as
    returned by ``crypt.mksalt()``.

    Note that these are non-standard extensions to Python 2.6's crypt.crypt()
    entrypoint, backported from 3.3: the standard Python 2.6 crypt.crypt()
    entrypoint requires two strings as the parameters, and does not support
    keyword arguments.
    """
    if salt is None or isinstance(salt, _Method):
        salt = mksalt(salt)
    return _crypt.crypt(word, salt)


#  available salting/crypto methods
METHOD_CRYPT = _Method('CRYPT', None, 2, 13)
METHOD_MD5 = _Method('MD5', '1', 8, 34)
METHOD_SHA256 = _Method('SHA256', '5', 16, 63)
METHOD_SHA512 = _Method('SHA512', '6', 16, 106)

methods = []
for _method in (METHOD_SHA512, METHOD_SHA256, METHOD_MD5):
    _result = crypt('', _method)
    if _result and len(_result) == _method.total_size:
        methods.append(_method)
methods.append(METHOD_CRYPT)
del _result, _method
