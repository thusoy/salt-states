import mock
import os
try:
    from importlib.machinery import SourceFileLoader
    def load_source(module, path):
        return SourceFileLoader(module, path).load_module()
except ImportError:
    # python 2
    import imp
    def load_source(module, path):
        return imp.load_source(module, path)


module = load_source('print_dependent_modules', os.path.join(os.path.dirname(__file__), 'print_dependent_modules.py'))


TEST_LSMOD_OUTPUT = '''\
Module                  Size  Used by
vboxsf                 41446  3
nfsd                  263032  2
auth_rpcgss            51211  1 nfsd
oid_registry           12419  1 auth_rpcgss
nfs_acl                12511  1 nfsd
nfs                   188136  0
lockd                  83389  2 nfs,nfsd
fscache                45542  1 nfs
sunrpc                237402  6 nfs,nfsd,auth_rpcgss,lockd,nfs_acl
ppdev                  16782  0
evdev                  17445  7
vboxvideo              12437  0
psmouse                99249  0
serio_raw              12849  0
drm                   249955  2 vboxvideo
parport_pc             26300  0
parport                35749  2 ppdev,parport_pc
pcspkr                 12595  0
i2c_piix4              20864  0
i2c_core               46012  2 drm,i2c_piix4
ac                     12715  0
vboxguest             193979  2 vboxsf
battery                13356  0
video                  18096  0
button                 12944  0
processor              28221  0
thermal_sys            27642  2 video,processor
autofs4                35529  2
ext4                  473802  1
crc16                  12343  1 ext4
mbcache                17171  1 ext4
jbd2                   82413  1 ext4
sg                     29973  0
sd_mod                 44356  3
crc_t10dif             12431  1 sd_mod
sr_mod                 21903  0
cdrom                  47424  1 sr_mod
crct10dif_generic      12581  1
crct10dif_common       12356  2 crct10dif_generic,crc_t10dif
ata_generic            12490  0
ata_piix               33592  0
ahci                   33291  2
libahci                27158  1 ahci
e1000                 122545  0
libata                177457  4 ahci,libahci,ata_generic,ata_piix
scsi_mod              191405  4 sg,libata,sd_mod,sr_mod
'''


def test_get_module_dependencies():
    uut = lambda x: list(module.get_module_dependencies(x))
    lsmod_mock = mock.Mock(return_value=TEST_LSMOD_OUTPUT)
    with mock.patch('subprocess.check_output', lsmod_mock):
        assert uut('foobar') == []
        assert uut('pcspkr') == ['pcspkr']
        assert uut('thermal_sys') == ['video', 'processor', 'thermal_sys']
        assert uut('i2c_core') == ['vboxvideo', 'drm', 'i2c_piix4', 'i2c_core']
        assert uut('libata') == ['ahci', 'libahci', 'ata_generic', 'ata_piix', 'libata']
        assert len(lsmod_mock.mock_calls) == 5
