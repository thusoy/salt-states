import imp
import os

import mock


module = imp.load_source('acme_dns', os.path.join(os.path.dirname(__file__), 'ext_pillar.py'))


def test_has_access():
    uut = module._has_access
    assert uut('*', '01.web.example.com') == True
    assert uut('*.example.com', '01.web.example.com') == True
    assert uut('01.*.example.com', '01.web.example.com') == True
    assert uut('*.example.com', '02.web.foobar.com') == False
