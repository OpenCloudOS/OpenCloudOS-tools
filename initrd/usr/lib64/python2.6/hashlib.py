# $Id: hashlib.py 66093 2008-08-31 16:34:18Z gregory.p.smith $
#
#  Copyright (C) 2005   Gregory P. Smith (greg@krypto.org)
#  Licensed to PSF under a Contributor Agreement.
#

__doc__ = """hashlib module - A common interface to many hash functions.

new(name, string='', usedforsecurity=True)
     - returns a new hash object implementing the given hash function;
       initializing the hash using the given string data.

       "usedforsecurity" is a non-standard extension for better supporting
       FIPS-compliant environments (see below)

Named constructor functions are also available, these are much faster
than using new():

md5(), sha1(), sha224(), sha256(), sha384(), and sha512()

More algorithms may be available on your platform but the above are
guaranteed to exist.

NOTE: If you want the adler32 or crc32 hash functions they are available in
the zlib module.

Choose your hash function wisely.  Some have known collision weaknesses.
sha384 and sha512 will be slow on 32 bit platforms.

Red Hat Enterprise Linux 6's implementation of hashlib uses OpenSSL.

OpenSSL has a "FIPS mode", which, if enabled, may restrict the available hashes
to only those that are compliant with FIPS regulations.  For example, it may
deny the use of MD5, on the grounds that this is not secure for uses such as
authentication, system integrity checking, or digital signatures.   

If you need to use such a hash for non-security purposes (such as indexing into
a data structure for speed), you can override the keyword argument
"usedforsecurity" from True to False to signify that your code is not relying
on the hash for security purposes, and this will allow the hash to be usable
even in FIPS mode.  This is not a standard feature of Python 2.6's hashlib, and
is included in RHEL6 to better support FIPS mode.

Hash objects have these methods:
 - update(arg): Update the hash object with the string arg. Repeated calls
                are equivalent to a single call with the concatenation of all
                the arguments.
 - digest():    Return the digest of the strings passed to the update() method
                so far. This may contain non-ASCII characters, including
                NUL bytes.
 - hexdigest(): Like digest() except the digest is returned as a string of
                double length, containing only hexadecimal digits.
 - copy():      Return a copy (clone) of the hash object. This can be used to
                efficiently compute the digests of strings that share a common
                initial substring.

For example, to obtain the digest of the string 'Nobody inspects the
spammish repetition':

    >>> import hashlib
    >>> m = hashlib.md5()
    >>> m.update("Nobody inspects")
    >>> m.update(" the spammish repetition")
    >>> m.digest()
    '\\xbbd\\x9c\\x83\\xdd\\x1e\\xa5\\xc9\\xd9\\xde\\xc9\\xa1\\x8d\\xf0\\xff\\xe9'

More condensed:

    >>> hashlib.sha224("Nobody inspects the spammish repetition").hexdigest()
    'a4337bc45a8fc544c03f52dc550cd6e1e87021bc896588bd79e901e2'

"""


def __hash_new(name, string='', usedforsecurity=True):
    """new(name, string='') - Return a new hashing object using the named algorithm;
    optionally initialized with a string.

    Override 'usedforsecurity' to False when using for non-security purposes in
    a FIPS environment
    """
    try:
        return _hashlib.new(name, string, usedforsecurity)
    except ValueError:
        raise

try:
    import _hashlib
    # use the wrapper of the C implementation
    new = __hash_new

    for opensslFuncName in filter(lambda n: n.startswith('openssl_'), dir(_hashlib)):
        funcName = opensslFuncName[len('openssl_'):]
        try:
            # try them all, some may not work due to the OpenSSL
            # version not supporting that algorithm.
            f = getattr(_hashlib, opensslFuncName)
            # We pass "usedforsecurity=False" to disable FIPS-based restrictions:
            # at this stage we're merely seeing if the function is callable,
            # rather than using it for actual work.
            f(usedforsecurity=False)
            # Use the C function directly (very fast)
            exec funcName + ' = f'
        except ValueError:
            raise
    # clean up our locals
    del f
    del opensslFuncName
    del funcName

except ImportError:
    # We don't have the _hashlib OpenSSL module?

    # We don't build the legacy modules
    raise
