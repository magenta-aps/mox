import base64
import zlib


def _gzipstring(s):
    compressor = zlib.compressobj(zlib.Z_DEFAULT_COMPRESSION,
                                  zlib.DEFLATED, 16 + zlib.MAX_WBITS)

    return compressor.compress(s) + compressor.flush()


def pack_token(token):
    '''Format an XML token string as saml-gzipped.'''
    return 'saml-gzipped ' + base64.standard_b64encode(_gzipstring(token))


def get_reason(doc):
    SOAP_NS = 'http://www.w3.org/2003/05/soap-envelope'

    raise Exception(' '.join(
        node.firstChild.wholeText
        for reason in doc.getElementsByTagNameNS(SOAP_NS, 'Reason')
        for node in reason.getElementsByTagNameNS(SOAP_NS, 'Text')
    ))


__all__ = (
    'get_reason',
    'pack_token',
)
