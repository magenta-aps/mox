class NoSuchJob(Exception):
    def __init__(self, message):
        super(NoSuchJob, self).__init__(message)
