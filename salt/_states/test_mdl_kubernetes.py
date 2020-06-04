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
kubernetes.__opts__ = {'test': False}
kubernetes.__env__ = 'base'


@skipIf(sys.version_info < (3, 0, 0), 'mdl_kubernetes is only supported on py3')
class KubernetesTestCase(TestCase):

    def setUp(self):
        self.mock_create_secret = Mock()
        self.mock_show_secret = Mock()
        self.mock_replace_secret = Mock()
        kubernetes.__salt__ = {
            'mdl_kubernetes.create_secret': self.mock_create_secret,
            'mdl_kubernetes.show_secret': self.mock_show_secret,
            'mdl_kubernetes.replace_secret': self.mock_replace_secret,
        }


    def tearDown(self):
        del kubernetes.__salt__


    def test_secret_present_too_many_parameters(self):
        ret = kubernetes.secret_present('test', data={'foo': 'bar'}, data_pillar='foo')
        assert ret['result'] == False
        assert 'mutually exclusive' in ret['comment']


    def test_secret_present_creates_secret(self):
        self.mock_show_secret.return_value = None
        self.mock_create_secret.return_value = {'data': {'foo': 'bar'}}

        ret = kubernetes.secret_present('test', data={'foo': 'bar'})

        assert ret['result'] == True
        assert ret['changes']['new'] == ['foo']
        self.mock_replace_secret.assert_not_called()


    def test_secret_present_exists(self):
        self.mock_show_secret.return_value = {'data': {'foo': 'bar'}}

        ret = kubernetes.secret_present('test', data={'foo': 'bar'})

        assert ret['result'] == True
        assert ret['changes'] == {}
        self.mock_replace_secret.assert_not_called()
        self.mock_create_secret.assert_not_called()


    def test_secret_present_exists_pillar_data(self):
        self.mock_show_secret.return_value = {'data': {'foo': 'pillar_value'}}

        with patch.dict(kubernetes.__salt__, {'pillar.get': lambda k: 'pillar_value'}):
            ret = kubernetes.secret_present('test', data_pillar={'foo': 'pillar_key'})

        assert ret['result'] == True
        assert ret['changes'] == {}
        self.mock_replace_secret.assert_not_called()
        self.mock_create_secret.assert_not_called()


    def test_secret_present_replaces_different(self):
        self.mock_show_secret.return_value = {'data': {'old_key': 'old_value'}}
        self.mock_replace_secret.return_value = {'data': {'foo': 'bar'}}

        ret = kubernetes.secret_present('test', data={'foo': 'bar'})

        assert ret['result'] == True
        assert ret['changes'] == {
            'old': ['old_key'],
            'new': ['foo'],
        }
        self.mock_create_secret.assert_not_called()


    def test_secret_present_replaces_different_pillar_data(self):
        self.mock_show_secret.return_value = {'data': {'old_key': 'old_value'}}
        self.mock_replace_secret.return_value = {'data': {'foo': 'bar'}}

        with patch.dict(kubernetes.__salt__, {'pillar.get': lambda k: 'bar'}):
            ret = kubernetes.secret_present('test', data_pillar={'foo': 'pillar_key'})

        assert ret['result'] == True
        assert ret['changes'] == {
            'old': ['old_key'],
            'new': ['foo'],
        }
        self.mock_create_secret.assert_not_called()
        replace_call_kwargs = self.mock_replace_secret.call_args[1]
        assert replace_call_kwargs['data'] == {'foo': 'bar'}
