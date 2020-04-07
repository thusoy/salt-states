import os
import sys
import tempfile
import textwrap
try:
    from unittest import mock
except:
    import mock

import pytest

sys.path.insert(0, os.path.dirname(__file__))

from external_ips import ext_pillar as uut


def test_external_ips():
    minion_ips = tempfile.NamedTemporaryFile()
    minion_ips.write(textwrap.dedent('''\
        other-minion 2.3.4.5
        test-minion 1.2.3.4 10.10.10.10
    ''').encode('utf-8'))
    minion_ips.flush()

    ret = uut('test-minion', {}, minion_ips_path=minion_ips.name)

    expected = ['1.2.3.4'] if sys.version_info > (3, 0, 0) else ['1.2.3.4', '10.10.10.10']

    assert ret == {
        'external_ips': expected,
    }
