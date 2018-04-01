#!/usr/bin/python

"""Esta funcao faz o rotate de uma array ate o termo passado
 exemplo:
 servers=['server-01','server-02','server-03']
 server='server-02'
 {{lookup('rotate',server,servers)}} 
 retorno: ['server-02','server-03','server-01']
"""
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import subprocess

from ansible.errors import AnsibleError
from ansible.plugins.lookup import LookupBase

class LookupModule(LookupBase):
    def run(self, terms, variables, **kwargs):
        ret = []
        item = terms[0]
        items = terms[1]
        for x in xrange(items.index(item)):
            items.append(items.pop(0))
        return items

