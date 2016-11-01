
from functools import wraps

def log_this(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        result = f(*args, **kwargs)
        print "Log this, including user & everything: {0}".format(result)
        return result

    return decorated
