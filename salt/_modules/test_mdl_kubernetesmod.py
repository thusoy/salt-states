# -*- coding: utf-8 -*-
"""
    :codeauthor: Jochen Breuer <jbreuer@suse.de>
"""
# pylint: disable=no-value-for-parameter

import base64
import os
import sys
from contextlib import contextmanager

import salt.utils.files
import salt.utils.platform

try:
    from unittest.mock import Mock, patch
except:
    from mock import Mock, patch

from unittest import TestCase, skipIf

sys.path.insert(0, os.path.dirname(__file__))


import mdl_kubernetesmod as kubernetes
kubernetes.__salt__ = {}


@contextmanager
def mock_kubernetes_library():
    """
    After fixing the bug in 1c821c0e77de58892c77d8e55386fac25e518c31,
    it caused kubernetes._cleanup() to get called for virtually every
    test, which blows up. This prevents that specific blow-up once
    """
    with patch("mdl_kubernetesmod.kubernetes") as mock_kubernetes_lib:
        yield mock_kubernetes_lib


@skipIf(
    not kubernetes.HAS_LIBS,
    "Kubernetes client lib is not installed. " "Skipping test_kubernetes.py",
)
class KubernetesTestCase(TestCase):
    """
    Test cases for mdl_kubernetes
    """

    def test_create_secret(self):
        with mock_kubernetes_library() as mock_kubernetes_lib:
            with patch.dict(
                kubernetes.__salt__, {"config.option": Mock(side_effect=self.settings)}
            ):
                mock_kubernetes_lib.client.CoreV1Api.return_value = Mock(
                    **{
                        "create_namespaced_secret.return_value.to_dict.return_value":
                            {'code': 200},
                    }
                )
                self.assertEqual(
                    kubernetes.create_secret("test", "default", {'key': 'secret'}),
                    {'code': 200},
                )
                mock_kubernetes_lib.client.CoreV1Api()\
                    .create_namespaced_secret()\
                    .to_dict.assert_called()


    def test_create_secret_from_pillar(self):
        with mock_kubernetes_library() as mock_kubernetes_lib:
            with patch.dict(
                kubernetes.__salt__, {
                    "config.option": Mock(side_effect=self.settings),
                    "pillar.get": lambda k: 'pillar_value',
                }
            ):
                mock_kubernetes_lib.client.CoreV1Api.return_value = Mock(
                    **{
                        "create_namespaced_secret.return_value.to_dict.return_value":
                            {'code': 200},
                    }
                )
                self.assertEqual(
                    kubernetes.create_secret("test", "default", data_pillar={'key': 'pillar:key'}),
                    {'code': 200},
                )
                secret_kwargs = mock_kubernetes_lib.client.V1Secret.call_args[1]
                expected_secret = base64.b64encode(b'pillar_value').decode('ascii')
                assert secret_kwargs['data'] == {'key': expected_secret}


    def test_replace_secret(self):
        with mock_kubernetes_library() as mock_kubernetes_lib:
            with patch.dict(
                kubernetes.__salt__, {"config.option": Mock(side_effect=self.settings)}
            ):
                mock_kubernetes_lib.client.CoreV1Api.return_value = Mock(
                    **{
                        "replace_namespaced_secret.return_value.to_dict.return_value":
                            {'code': 200},
                    }
                )
                self.assertEqual(
                    kubernetes.replace_secret("test", {'key': 'secret'}),
                    {'code': 200},
                )
                mock_kubernetes_lib.client.CoreV1Api()\
                    .replace_namespaced_secret()\
                    .to_dict.assert_called()

    def test_replace_secret_from_pillar(self):
        with mock_kubernetes_library() as mock_kubernetes_lib:
            with patch.dict(
                kubernetes.__salt__, {
                    "config.option": Mock(side_effect=self.settings),
                    "pillar.get": lambda k: 'pillar_value',
                }
            ):
                mock_kubernetes_lib.client.CoreV1Api.return_value = Mock(
                    **{
                        "replace_namespaced_secret.return_value.to_dict.return_value":
                            {'code': 200},
                    }
                )
                self.assertEqual(
                    kubernetes.replace_secret("test", "default", data_pillar={'key': 'pillar:key'}),
                    {'code': 200},
                )
                secret_kwargs = mock_kubernetes_lib.client.V1Secret.call_args[1]
                expected_secret = base64.b64encode(b'pillar_value').decode('ascii')
                assert secret_kwargs['data'] == {'key': expected_secret}

    def test_show_secret(self):
        with mock_kubernetes_library() as mock_kubernetes_lib:
            with patch.dict(
                kubernetes.__salt__, {"config.option": Mock(side_effect=self.settings)}
            ):
                mock_kubernetes_lib.client.CoreV1Api.return_value = Mock(
                    **{
                        "read_namespaced_secret.return_value.to_dict.return_value":
                            {'data': {'key': 'Zm9vYmFy'}}, # "foobar" encoded with base64
                    }
                )
                self.assertEqual(
                    kubernetes.show_secret("test", "default", {'key': 'secret'}),
                    {'data': {'key': 'foobar'}},
                )
                mock_kubernetes_lib.client.CoreV1Api()\
                    .read_namespaced_secret()\
                    .to_dict.assert_called()

    def test_nodes(self):
        """
        Test node listing.
        :return:
        """
        with mock_kubernetes_library() as mock_kubernetes_lib:
            with patch.dict(
                kubernetes.__salt__, {"config.option": Mock(side_effect=self.settings)}
            ):
                mock_kubernetes_lib.client.CoreV1Api.return_value = Mock(
                    **{
                        "list_node.return_value.to_dict.return_value": {
                            "items": [{"metadata": {"name": "mock_node_name"}}]
                        }
                    }
                )
                self.assertEqual(kubernetes.nodes(), ["mock_node_name"])
                self.assertTrue(
                    kubernetes.kubernetes.client.CoreV1Api().list_node().to_dict.called
                )

    def test_deployments(self):
        """
        Tests deployment listing.
        :return:
        """
        with mock_kubernetes_library() as mock_kubernetes_lib:
            with patch.dict(
                kubernetes.__salt__, {"config.option": Mock(side_effect=self.settings)}
            ):
                mock_kubernetes_lib.client.ExtensionsV1beta1Api.return_value = Mock(
                    **{
                        "list_namespaced_deployment.return_value.to_dict.return_value": {
                            "items": [{"metadata": {"name": "mock_deployment_name"}}]
                        }
                    }
                )
                self.assertEqual(kubernetes.deployments(), ["mock_deployment_name"])
                # pylint: disable=E1120
                self.assertTrue(
                    kubernetes.kubernetes.client.ExtensionsV1beta1Api()
                    .list_namespaced_deployment()
                    .to_dict.called
                )
                # pylint: enable=E1120

    def test_services(self):
        """
        Tests services listing.
        :return:
        """
        with mock_kubernetes_library() as mock_kubernetes_lib:
            with patch.dict(
                kubernetes.__salt__, {"config.option": Mock(side_effect=self.settings)}
            ):
                mock_kubernetes_lib.client.CoreV1Api.return_value = Mock(
                    **{
                        "list_namespaced_service.return_value.to_dict.return_value": {
                            "items": [{"metadata": {"name": "mock_service_name"}}]
                        }
                    }
                )
                self.assertEqual(kubernetes.services(), ["mock_service_name"])
                # pylint: disable=E1120
                self.assertTrue(
                    kubernetes.kubernetes.client.CoreV1Api()
                    .list_namespaced_service()
                    .to_dict.called
                )
                # pylint: enable=E1120

    def test_pods(self):
        """
        Tests pods listing.
        :return:
        """
        with mock_kubernetes_library() as mock_kubernetes_lib:
            with patch.dict(
                kubernetes.__salt__, {"config.option": Mock(side_effect=self.settings)}
            ):
                mock_kubernetes_lib.client.CoreV1Api.return_value = Mock(
                    **{
                        "list_namespaced_pod.return_value.to_dict.return_value": {
                            "items": [{"metadata": {"name": "mock_pod_name"}}]
                        }
                    }
                )
                self.assertEqual(kubernetes.pods(), ["mock_pod_name"])
                # pylint: disable=E1120
                self.assertTrue(
                    kubernetes.kubernetes.client.CoreV1Api()
                    .list_namespaced_pod()
                    .to_dict.called
                )
                # pylint: enable=E1120

    def test_delete_deployments(self):
        """
        Tests deployment deletion
        :return:
        """
        with mock_kubernetes_library() as mock_kubernetes_lib:
            with patch(
                "mdl_kubernetesmod.show_deployment", Mock(return_value=None)
            ):
                with patch.dict(
                    kubernetes.__salt__,
                    {"config.option": Mock(side_effect=self.settings)},
                ):
                    mock_kubernetes_lib.client.V1DeleteOptions = Mock(return_value="")
                    mock_kubernetes_lib.client.ExtensionsV1beta1Api.return_value = Mock(
                        **{
                            "delete_namespaced_deployment.return_value.to_dict.return_value": {
                                "code": ""
                            }
                        }
                    )
                    self.assertEqual(
                        kubernetes.delete_deployment("test"), {"code": 200}
                    )
                    # pylint: disable=E1120
                    self.assertTrue(
                        kubernetes.kubernetes.client.ExtensionsV1beta1Api()
                        .delete_namespaced_deployment()
                        .to_dict.called
                    )
                    # pylint: enable=E1120

    def test_create_deployments(self):
        """
        Tests deployment creation.
        :return:
        """
        with mock_kubernetes_library() as mock_kubernetes_lib:
            with patch.dict(
                kubernetes.__salt__, {"config.option": Mock(side_effect=self.settings)}
            ):
                mock_kubernetes_lib.client.ExtensionsV1beta1Api.return_value = Mock(
                    **{
                        "create_namespaced_deployment.return_value.to_dict.return_value": {}
                    }
                )
                self.assertEqual(
                    kubernetes.create_deployment(
                        "test", "default", {}, {}, None, None, None
                    ),
                    {},
                )
                # pylint: disable=E1120
                self.assertTrue(
                    kubernetes.kubernetes.client.ExtensionsV1beta1Api()
                    .create_namespaced_deployment()
                    .to_dict.called
                )
                # pylint: enable=E1120

    @staticmethod
    def settings(name, value=None):
        """
        Test helper
        :return: settings or default
        """
        data = {
            "kubernetes.kubeconfig": "/home/testuser/.minikube/kubeconfig.cfg",
            "kubernetes.context": "minikube",
        }
        return data.get(name, value)

    def test_setup_kubeconfig_file(self):
        """
        Test that the `kubernetes.kubeconfig` configuration isn't overwritten
        :return:
        """
        with mock_kubernetes_library() as mock_kubernetes_lib:
            with patch.dict(
                kubernetes.__salt__, {"config.option": Mock(side_effect=self.settings)}
            ):
                mock_kubernetes_lib.config.load_kube_config = Mock()
                config = kubernetes._setup_conn()
                self.assertEqual(
                    self.settings("kubernetes.kubeconfig"), config["kubeconfig"],
                )

    def test_setup_kubeconfig_data_overwrite(self):
        """
        Test that provided `kubernetes.kubeconfig` configuration is overwritten
        by provided kubeconfig_data in the command
        :return:
        """
        with mock_kubernetes_library() as mock_kubernetes_lib:
            with patch.dict(
                kubernetes.__salt__, {"config.option": Mock(side_effect=self.settings)}
            ):
                mock_kubernetes_lib.config.load_kube_config = Mock()
                config = kubernetes._setup_conn(
                    kubeconfig_data="MTIzNDU2Nzg5MAo=", context="newcontext"
                )
                check_path = os.path.join("/tmp", "salt-kubeconfig-")
                if salt.utils.platform.is_windows():
                    check_path = os.path.join(os.environ.get("TMP"), "salt-kubeconfig-")
                elif salt.utils.platform.is_darwin():
                    check_path = os.path.join(
                        os.environ.get("TMPDIR", "/tmp"), "salt-kubeconfig-"
                    )
                self.assertTrue(
                    config["kubeconfig"].lower().startswith(check_path.lower())
                )
                self.assertTrue(os.path.exists(config["kubeconfig"]))
                with salt.utils.files.fopen(config["kubeconfig"], "r") as kcfg:
                    self.assertEqual("1234567890\n", kcfg.read())
                kubernetes._cleanup(**config)

    def test_node_labels(self):
        """
        Test kubernetes.node_labels
        :return:
        """
        with patch("mdl_kubernetesmod.node") as mock_node:
            mock_node.return_value = {
                "metadata": {
                    "labels": {
                        "kubernetes.io/hostname": "minikube",
                        "kubernetes.io/os": "linux",
                    }
                }
            }
            self.assertEqual(
                kubernetes.node_labels("minikube"),
                {"kubernetes.io/hostname": "minikube", "kubernetes.io/os": "linux"},
            )

    def test_adding_change_cause_annotation(self):
        """
        Tests adding a `kubernetes.io/change-cause` annotation just like
        kubectl [apply|create|replace] --record does
        :return:
        """
        with patch(
            "mdl_kubernetesmod.sys.argv", ["/usr/bin/salt-call", "state.apply"]
        ) as mock_sys:
            func = getattr(kubernetes, "__dict_to_object_meta")
            data = func(name="test-pod", namespace="test", metadata={})

            self.assertEqual(data.name, "test-pod")
            self.assertEqual(data.namespace, "test")
            self.assertEqual(
                data.annotations,
                {"kubernetes.io/change-cause": "/usr/bin/salt-call state.apply"},
            )

            # Ensure any specified annotations aren't overwritten
            test_metadata = {"annotations": {"kubernetes.io/change-cause": "NOPE"}}
            data = func(name="test-pod", namespace="test", metadata=test_metadata)

            self.assertEqual(data.annotations, {"kubernetes.io/change-cause": "NOPE"})

    def test_enforce_only_strings_dict(self):
        func = getattr(kubernetes, "__enforce_only_strings_dict")
        data = {
            "unicode": 1,
            2: 2,
        }
        self.assertEqual(
            {"unicode": "1", "2": "2"}, func(data),
        )
