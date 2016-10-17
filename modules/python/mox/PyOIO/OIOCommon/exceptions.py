
class InvalidOIOException(Exception):

    def __init__(self, e):
        Exception.__init__(self, 'Invalid OIO: %s' % e)
