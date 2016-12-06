from . import adfs
from . import util
from . import wso2

from .. import settings


def get_idp_type():
    try:
        return settings.SAML_IDP_TYPE
    except AttributeError:
        try:
            return 'adfs' if settings.USE_SIMPLE_SAML else 'wso2'
        except AttributeError:
            return 'wso2'


def get_token(username, passwd, pack=True, pretty_print=False):
    idp_type = get_idp_type()
    idp_url = settings.SAML_IDP_URL
    endpoint = settings.SAML_MOX_ENTITY_ID

    if idp_type == 'wso2':
        getter = wso2.get_token
    elif idp_type == 'adfs':
        getter = adfs.get_token
    else:
        raise Exception('unknown SAML_IDP_TYPE {!r}'.format(idp_type))

    token = getter(username, passwd, idp_url, endpoint, pretty_print)

    return util.pack_token(token) if pack else token


__all__ = (
    'get_token',
)
