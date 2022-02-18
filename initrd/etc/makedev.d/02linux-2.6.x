# This file is written almost directly from the devices.txt file kept at
# http://www.lanana.org/docs/device-list/devices.txt, as of 30 August 2004
# Type Perms User Group Major Minor Inc Count Base
#
# USB devices have their own configuration file.
#

c $KMEM                  1   2  1   1 kmem

b $FLOPPY                2   0  1   4 fd%d
b $FLOPPY                2 128  1   4 fd%d 4

b $FLOPPY                2   4  1   4 fd%dd360
b $FLOPPY                2  20  1   4 fd%dh360
b $FLOPPY                2  48  1   4 fd%dh410
b $FLOPPY                2  64  1   4 fd%dh420
b $FLOPPY                2  24  1   4 fd%dh720
b $FLOPPY                2  80  1   4 fd%dh880
b $FLOPPY                2   8  1   4 fd%dh1200
b $FLOPPY                2  40  1   4 fd%dh1440
b $FLOPPY                2  56  1   4 fd%dh1476
b $FLOPPY                2  72  1   4 fd%dh1494
b $FLOPPY                2  92  1   4 fd%dh1660

b $FLOPPY                2  12  1   4 fd%du360
b $FLOPPY                2  16  1   4 fd%du720
b $FLOPPY                2 120  1   4 fd%du800
b $FLOPPY                2  52  1   4 fd%du820
b $FLOPPY                2  68  1   4 fd%du830
b $FLOPPY                2  84  1   4 fd%du1040
b $FLOPPY                2  88  1   4 fd%du1120
b $FLOPPY                2  28  1   4 fd%du1440
b $FLOPPY                2 124  1   4 fd%du1660
b $FLOPPY                2  44  1   4 fd%du1680
b $FLOPPY                2  60  1   4 fd%du1722
b $FLOPPY                2  76  1   4 fd%du1743
b $FLOPPY                2  96  1   4 fd%du1760
b $FLOPPY                2 116  1   4 fd%du1840
b $FLOPPY                2 100  1   4 fd%du1920
b $FLOPPY                2  32  1   4 fd%du2880
b $FLOPPY                2 104  1   4 fd%du3200
b $FLOPPY                2 108  1   4 fd%du3520
b $FLOPPY                2 112  1   4 fd%du3840

b $FLOPPY                2 132  1   4 fd%dd360  4
b $FLOPPY                2 148  1   4 fd%dh360  4
b $FLOPPY                2 176  1   4 fd%dh410  4
b $FLOPPY                2 192  1   4 fd%dh420  4
b $FLOPPY                2 152  1   4 fd%dh720  4
b $FLOPPY                2 208  1   4 fd%dh880  4
b $FLOPPY                2 136  1   4 fd%dh1200 4
b $FLOPPY                2 168  1   4 fd%dh1440 4
b $FLOPPY                2 184  1   4 fd%dh1476 4
b $FLOPPY                2 200  1   4 fd%dh1494 4
b $FLOPPY                2 220  1   4 fd%dh1660 4

b $FLOPPY                2 140  1   4 fd%du360  4
b $FLOPPY                2 144  1   4 fd%du720  4
b $FLOPPY                2 248  1   4 fd%du800  4
b $FLOPPY                2 180  1   4 fd%du820  4
b $FLOPPY                2 196  1   4 fd%du830  4
b $FLOPPY                2 212  1   4 fd%du1040 4
b $FLOPPY                2 216  1   4 fd%du1120 4
b $FLOPPY                2 156  1   4 fd%du1440 4
b $FLOPPY                2 252  1   4 fd%du1660 4
b $FLOPPY                2 172  1   4 fd%du1680 4
b $FLOPPY                2 188  1   4 fd%du1722 4
b $FLOPPY                2 204  1   4 fd%du1743 4
b $FLOPPY                2 224  1   4 fd%du1760 4
b $FLOPPY                2 244  1   4 fd%du1840 4
b $FLOPPY                2 228  1   4 fd%du1920 4
b $FLOPPY                2 160  1   4 fd%du2880 4
b $FLOPPY                2 232  1   4 fd%du3200 4
b $FLOPPY                2 236  1   4 fd%du3520 4
b $FLOPPY                2 240  1   4 fd%du3840 4

b $FLOPPY                2   4  1   4 fd%dCompaQ
b $FLOPPY                2 132  1   4 fd%dCompaQ 4

c $CONSOLE              10   4  1   1 amigamouse
c $CONSOLE              10   5  1   1 atarimouse
c $CONSOLE              10   6  1   1 sunmouse
c $CONSOLE              10   7  1   1 amigamouse1
c $CONSOLE              10   8  1   1 smouse
c $CONSOLE              10   9  1   1 pc110pad
c $CONSOLE              10  10  1   1 adbmouse
c $ROOT                 10 139  1   1 openprom
c $CONSOLE              10 145  1   1 hfmodem
c $CONSOLE              10 154  1   1 pmu
c $ROOT                 10 158  1   1 nwbutton
c $ROOT                 10 159  1   1 nwdebug
c $ROOT                 10 160  1   1 nwflash
c $ROOT                 10 165  1   1 vmmon
c $ROOT                 10 166  1   1 i2o/ctl
c $SERIAL               10 167  1   1 specialix_sxctl
c $SERIAL               10 169  1   1 specialix_rioctl
c $ROOT                 10 170  1   1 thinkpad/thinkpad
c $ROOT                 10 171  1   1 srripc
c $ROOT                 10 181  1   1 toshiba

c $ROOT                 10 186  1   1 atomicps
c $ROOT                 10 191  1   1 pcl181
c $ROOT                 10 192  1   1 nas_xbus
c $ROOT                 10 193  1   1 d7s
c $ROOT                 10 194  1   1 zkshim
c $CONSOLE              10 195  1   1 elographics/e2201

# Where did 196 and 197 go?

c $ROOT                 10 198  1   1 sexec
c $CONSOLE              10 199  1   1 scanners/cuecat
c $ROOT                 10 201  1   1 button/gulpb
c $ROOT                 10 202  1   1 emd/ctl

# Where did 203 go?

c $ROOT                 10 219  1   1 modems/mwave
c $ROOT                 10 221  1   1 mvista/hssdsi
c $ROOT                 10 222  1   1 mvista/hasi

c $STORAGE              12   2  1   1 ntpqic11
c $STORAGE              12   3  1   1 tpqic11
c $STORAGE              12   4  1   1 ntpqic24
c $STORAGE              12   5  1   1 tpqic24
c $STORAGE              12   6  1   1 ntpqic120
c $STORAGE              12   7  1   1 tpqic120
c $STORAGE              12   8  1   1 ntpqic150
c $STORAGE              12   9  1   1 tpqic150

b $STORAGE              15   0  1   1 sonycd

b $STORAGE              16   0  1   1 gscd

b $STORAGE              17   0  1   1 optcd

b $STORAGE              18   0  1   1 sjcd

b $STORAGE              23   0  1   1 mcd

b $STORAGE              24   0  1   1 cdu535

b $STORAGE              25   0  1   4 sbpcd%d

b $STORAGE              26   0  1   4 sbpcd%d 4

b $STORAGE              27   0  1   4 sbpcd%d 8

c $ROOT                 28   0  1   4 staliomem%d
b $STORAGE              28   0  1   4 sbpcd%d 12

b $STORAGE              29   0  1   1 aztcd

b $STORAGE              30   0  1   1 cm205cd

b $STORAGE              32   0  1   1 cm206cd

c $ROOT                 41   0  1   1 yamm
b $STORAGE              41   0  1   1 bpcd

c $SERIAL               44   0  1  64 cui%d
b $STORAGE              44   0  1 256 ftl%c%|%d a 16

c $ROOT                 45   0  1  64 isdn%d
c $ROOT                 45  64  1  64 isdnctrl%d

c $ROOT                 53   3  1   3 icd_bdm%d

c $ROOT                 55   0  1   1 dsp56k

# Here there be dragons.
b $STORAGE              65   0  1 160 sd%c%|%d q 16
b $STORAGE              65 160  1  96 sda%c%|%d a 16

b $STORAGE              66   0  1 256 sda%c%|%d g 16

b $STORAGE              67   0  1  64 sda%c%|%d w 16
b $STORAGE              67  64  1 192 sdb%c%|%d a 16

b $STORAGE              68   0  1 224 sdb%c%|%d m 16
b $STORAGE              68 224  1  32 sdc%c%|%d a 16

b $STORAGE              69   0  1 256 sdc%c%|%d c 16

b $STORAGE              70   0  1 128 sdc%c%|%d s 16
b $STORAGE              70 128  1 128 sdd%c%|%d a 16

b $STORAGE              71   0  1 256 sdd%c%|%d i 16

b $STORAGE              80   0  1 256 i2o/hd%c%|%d a 16

b $STORAGE              81   0  1 160 i2o/hd%c%|%d q 16
b $STORAGE              81 160  1  96 i2o/hda%c%|%d a 16

c $CONSOLE              82   0  1   4 winradio%d

b $STORAGE              82   0  1 256 i2o/hda%c%|%d g 16

c $CONSOLE              83   0  1  16 mga_vid%d

b $STORAGE              83   0  1  64 i2o/hda%c%|%d w 16
b $STORAGE              83  64  1 192 i2o/hdb%c%|%d a 16

b $STORAGE              84   0  1 224 i2o/hdb%c%|%d m 16
b $STORAGE              84 224  1  32 i2o/hdc%c%|%d a 16

b $STORAGE              85   0  1 256 i2o/hdc%c%|%d c 16

b $STORAGE              86   0  1 128 i2o/hdc%c%|%d s 16
b $STORAGE              86 128  1 128 i2o/hdd%c%|%d a 16

b $STORAGE              87   0  1 256 i2o/hdd%c%|%d i 16

# devices.txt gives us 64 numbered dasd devices, with apparently up to three
# lettered partitions on each; the older s390-specific file used 64 lettered
# devices with up to three numbered partitions on each; the second partition on
# the second disk is now dasd1b (94/6) instead of dasdb2 (94/6)
b $STORAGE              94   0  4  64 dasd%d
b $STORAGE              94   1  4  64 dasd%da
b $STORAGE              94   2  4  64 dasd%db
b $STORAGE              94   3  4  64 dasd%dc

b $STORAGE              96   0  1 256 inftl%c%|%d a 16

b $STORAGE             101   0  1 256 amiraid/ar%d%|p%d 0 16

b $STORAGE             112   0  1 208 iseries/vd%c%|%d a 8
b $STORAGE             112 208  1  48 iseries/vda%c%|%d a 8

b $STORAGE             113   0  1   8 iseries/vcd%c a

b $STORAGE             115   0  1 256 nwfs/v%d

b $STORAGE             116   0  1 256 umem/d%d%|p%d 0 16

b $STORAGE             128   0  1  32 sdd%c%|%d y 16
b $STORAGE             128  32  1 224 sde%c%|%d a 16

b $STORAGE             129   0  1 192 sde%c%|%d o 16
b $STORAGE             129 192  1  64 sdf%c%|%d a 16

b $STORAGE             130   0  1 256 sdf%c%|%d e 16

b $STORAGE             131   0  1  96 sdf%c%|%d u 16
b $STORAGE             131  96  1 160 sdg%c%|%d a 16

b $STORAGE             132   0  1 256 sdg%c%|%d k 16

b $STORAGE             133   0  1 256 sdh%c%|%d a 16

b $STORAGE             134   0  1 160 sdh%c%|%d q 16
b $STORAGE             134 160  1  96 sdi%c%|%d a 16

b $STORAGE             135   0  1 256 sdi%c%|%d g 16

b $STORAGE             153   0  1 256 emd/%d%|p%d 0 16

b $STORAGE             160   0  1 256 sx8/%d%|p%d 0 32

b $STORAGE             161   0  1 256 sx8/%d%|p%d 8 32

b $STORAGE             180   0  1 128 ub%c%|%d a 8

c $CONSOLE             195   0  1 255 nvidia%d
c $CONSOLE             195 255  1   1 nvidiactl

c $STORAGE             200   0  1   1 vx/config
c $STORAGE             200   1  1   1 vx/trace
c $STORAGE             200   2  1   1 vx/iod
c $STORAGE             200   3  1   1 vx/info
c $STORAGE             200   4  1   1 vx/task
c $STORAGE             200   5  1   1 vx/taskmon

# We can skip 201 because Veritas user-land handles it.

b $STORAGE             202   0  1 256 xvd%c%|%d a 16

c $ROOT                207   0  1   1 cpqhealth/cpqw
c $ROOT                207   1  1   1 cpqhealth/crom
c $ROOT                207   2  1   1 cpqhealth/cdt
c $ROOT                207   3  1   1 cpqhealth/cevt
c $ROOT                207   4  1   1 cpqhealth/casr
c $ROOT                207   5  1   1 cpqhealth/cecc
c $ROOT                207   6  1   1 cpqhealth/cmca
c $ROOT                207   7  1   1 cpqhealth/ccsm
c $ROOT                207   8  1   1 cpqhealth/cnmi
c $ROOT                207   9  1   1 cpqhealth/css
c $ROOT                207  10  1   1 cpqhealth/cram
c $ROOT                207  11  1   1 cpqhealth/cpci

c $ROOT                230   0  1  32 iseries/vt%d
c $ROOT                230  32  1  32 iseries/vt%dl
c $ROOT                230  64  1  32 iseries/vt%dm
c $ROOT                230  96  1  32 iseries/vt%da
c $ROOT                230 128  1  32 iseries/nvt%d
c $ROOT                230 160  1  32 iseries/nvt%dl
c $ROOT                230 192  1  32 iseries/nvt%dm
c $ROOT                230 224  1  32 iseries/nvt%da

c $ROOT                231   0  1  64 infiniband/umad%d
c $ROOT                231  64  1  64 infiniband/issm%d
c $ROOT                231 128  1  32 infiniband/uverbs%d

