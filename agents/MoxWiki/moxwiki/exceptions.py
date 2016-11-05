
class TemplateNotFoundException(Exception):
    def __init__(self, template_name):
        super(TemplateNotFoundException, self).__init__("Template '%' was not found", template_name)