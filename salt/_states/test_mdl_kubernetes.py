# -*- coding: utf-8 -*-

import os
import sys

try:
    from unittest.mock import Mock, patch
except:
    from mock import Mock, patch

from unittest import TestCase, skipIf

sys.path.insert(0, os.path.dirname(__file__))


import mdl_kubernetes as kubernetes


@skipIf(sys.version_info < (3, 0, 0), 'mdl_kubernetes is only supported on py3')
class KubernetesTestCase(TestCase):

    def test_secret_present_too_many_parameters(self):
        ret = kubernetes.secret_present('test', data={'foo': 'bar'}, data_pillar='foo')
        assert ret['result'] == False
        assert 'mutually exclusive' in ret['comment']
