#!/usr/bin/python
#Usage E.g: ./apply-template.py facet.txt dbtyper-specific.jinja.sql

import jinja2
import os
import sys
from collections import OrderedDict


templateLoader = jinja2.FileSystemLoader( searchpath="./templates" )
templateEnv = jinja2.Environment( loader=templateLoader )
TEMPLATE_FILE = sys.argv[2]
template = templateEnv.get_template( TEMPLATE_FILE )
templateVars = eval(open("./template-values/"+sys.argv[1], 'r').read())
templateVars["script_signature"]=os.path.basename(__file__)+" "+sys.argv[1]+" "+sys.argv[2]
templateVars['tilstande']=OrderedDict(templateVars['tilstande'])#it is important that the order is stable, as some templates relies on this
templateVars['attributter']=OrderedDict(templateVars['attributter'])#it is important that the order is stable, as some templates relies on this
outputText = template.render( templateVars )
print(outputText)