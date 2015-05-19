#!/usr/bin/python
#Usage: ./generate-oio-type-tbls.py facet.txt dbtyper-specific.jinja.sql

import jinja2
import os
import sys


templateLoader = jinja2.FileSystemLoader( searchpath="./templates" )
templateEnv = jinja2.Environment( loader=templateLoader )
TEMPLATE_FILE = sys.argv[2]
template = templateEnv.get_template( TEMPLATE_FILE )
templateVars = eval(open("./template-values/"+sys.argv[1], 'r').read())
templateVars["script_name"]=os.path.basename(__file__)
outputText = template.render( templateVars )
print(outputText)