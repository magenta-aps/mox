import pexpect
import re

from ..settings import MOX_BASE_DIR

send_pwd_with_ipc = True
try:
    from shlex import quote as cmd_quote
except ImportError:
    from pipes import quote as cmd_quote


def get_packed_token(username, password, sts=''):
    params = ['-u', username, '-a', sts, '-s']
    if send_pwd_with_ipc:
        params.append('-p')
    else:
        params.extend(['-p', password])

    child = pexpect.spawn(
        os.path.join(MOX_BASE_DIR, 'auth.sh') +
        ' ' + ' '.join(cmd_quote(param) for param in params))
    try:
        if send_pwd_with_ipc:
            i = child.expect([pexpect.TIMEOUT, "Password:"])
            if i == 0:
                raise Exception("Error requesting token: "
                                "no password prompt")
            else:
                child.sendline(password)
        output = child.read()
        m = re.search("saml-gzipped\s+(.+?)\s", output)
        if m is not None:
            token = m.group(1)
            return "saml-gzipped " + token
        else:
            m = re.search("Incorrect password!", output)
            if m is not None:
                raise Exception("Error requesting token: "
                                "invalid username or password")
            else:
                raise Exception(
                    "Error requesting token: " + output
                )
    except pexpect.TIMEOUT:
        raise Exception("Timeout while requesting token")
    finally:
        child.close()
