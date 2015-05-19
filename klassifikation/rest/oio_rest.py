

class OIOStandardHierarchy(object):
    """Implement API for entire hierarchy."""
    
    _classes = []

    @classmethod
    def setup_api(cls, flask, base_url):
        """Set up API for the classes included in the hierarchy.
        
        Note that version number etc. may have to be added to the URL."""
        for c in cls._classes:
            c.create_api(cls._name, flask, base_url)


class OIORestObject(object):
    """
    Implement an OIO object - manage access to database layer for this object.

    This class is intended to be subclassed, but not to be initialized.
    """

    @staticmethod
    def get_objects():
        raise NotImplementedError

    @staticmethod
    def get_object(uuid):
        raise NotImplementedError

    @staticmethod
    def put_object(uuid):
        raise NotImplementedError

    @staticmethod
    def create_object():
        raise NotImplementedError

    @staticmethod
    def delete_object(uuid):
        raise NotImplementedError

    @classmethod
    def create_api(cls, hierarchy, flask, base_url):
        """Set up API with correct database access functions."""
        hierarchy = hierarchy.lower()
        class_name = cls.__name__.lower()
        class_url = u"{0}/{1}/{2}".format(base_url,
                                          hierarchy,
                                          cls.__name__.lower())
        object_url = u"{0}/<uuid>".format(class_url)

        flask.add_url_rule(class_url, u'_'.join([cls.__name__, 'get_objects']),
                         cls.get_objects, methods=['GET'])

        flask.add_url_rule(object_url, u'_'.join([cls.__name__, 'get_object']),
                         cls.get_object, methods=['GET'])

        flask.add_url_rule(object_url, u'_'.join([cls.__name__, 'put_object']),
                         cls.put_object, methods=['PUT'])

        flask.add_url_rule(
            class_url, u'_'.join([cls.__name__, 'create_object']),
            cls.create_object, methods=['POST']
        )

        flask.add_url_rule(
            object_url, u'_'.join([cls.__name__, 'delete_object']),
            cls.get_object, methods=['DELETE']
        )

