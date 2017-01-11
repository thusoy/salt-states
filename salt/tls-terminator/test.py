import imp
import os

module = imp.load_source('tls_terminator', os.path.join(os.path.dirname(__file__), 'init.sls'))

def test_is_external_backend():
    uut = module.parse_backend
    assert uut('https://example.com') == ('0/0', 443, True, 'both')
    assert uut('https://example.com:8000') == ('0/0', 8000, True, 'both')
    assert uut('https://10.10.10.10') == ('10.10.10.10', 443, True, 'ipv4')
    assert uut('https://10.10.10.10:5000') == ('10.10.10.10', 5000, True, 'ipv4')
    assert uut('http://example.com') == ('0/0', 80, True, 'both')
    assert uut('http://10.10.10.10') == ('10.10.10.10', 80, True, 'ipv4')
    assert uut('https://[2001:0db8:85a3:08d3:1319:8a2e:0370:7344]:8000') == \
        ('2001:db8:85a3:8d3:1319:8a2e:370:7344', 8000, True, 'ipv6')

    assert uut('https://127.0.0.1') == ('127.0.0.1', 443, False, 'ipv4')
    assert uut('http://127.0.0.1') == ('127.0.0.1', 80, False, 'ipv4')
    assert uut('https://127.43.25.21') == ('127.43.25.21', 443, False, 'ipv4')
    assert uut('http://[::1]') == ('::1', 80, False, 'ipv6')
    assert uut('https://[::1]:5000') == ('::1', 5000, False, 'ipv6')


def test_get_port_sets():
    uut = module.get_port_sets
    assert uut([]) == []
    assert uut([1]) == ['1']
    assert uut([1, 2]) == ['1:2']
    assert uut([1, 2, 4]) == ['1:2,4']
    assert uut([1, 3,4,5, 7]) == ['1,3:5,7']
    assert uut(range(0, 31, 2)) == ['0,2,4,6,8,10,12,14,16,18,20,22,24,26,28', '30']






# use this to test the full state:
# tls-terminator:
#     example.com:
#         backends:
#             /1: http://10.10.10.17:8001
#             /2: http://10.10.10.17:8002
#             /3: http://10.10.10.17:8003
#             /4: http://10.10.10.17:8004
#             /5: http://10.10.10.17:8005
#             /6: http://10.10.10.17:8006
#             /7: http://10.10.10.17:8007
#             /8: http://10.10.10.17:8008
#             /9: http://10.10.10.17:8009
#             /10: http://10.10.10.17:8010
#             /11: http://10.10.10.17:8011
#             /12: http://10.10.10.17:8012
#             /13: http://10.10.10.17:8013
#             /14: http://10.10.10.17:8014
#             /15: http://10.10.10.17:8015
#             /16: http://10.10.10.17:8016
#             /17: http://10.10.10.17:8017
#             /18: http://10.10.10.17:8018
