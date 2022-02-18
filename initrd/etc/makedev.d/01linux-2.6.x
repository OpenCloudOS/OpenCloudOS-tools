# This file is written almost directly from the devices.txt file kept at
# http://www.lanana.org/docs/device-list/devices.txt, as of 30 August 2004
# Type Perms User Group Major Minor Inc Count Base
#
# USB devices have their own configuration file.
#

c $KMEM                  1   1  1   1 mem
c $ALLWRITE              1   3  1   1 null
c $KMEM                  1   4  1   1 port
c $ALLWRITE              1   5  1   1 zero
c $ROOT                  1   6  1   1 core
c $ALLWRITE              1   7  1   1 full
c $ALLREAD               1   8  1   1 random
c $ALLREAD               1   9  1   1 urandom
c $ALLREAD               1  10  1   1 aio
c $ROOT                  1  11  1   1 kmsg

b $STORAGE               1   0  1 128 ram%d
b $STORAGE               1 250  1   1 initrd

c $PTY                   2   0  1 176 pty%c%x p 16
c $PTY                   2 176  1  80 pty%c%x a 16

c $PTY                   3   0  1 176 tty%c%x p 16
c $PTY                   3 176  1  80 tty%c%x a 16

# See fs/partitions/check.c in the kernel sources for the source of this
# limitation.
b $STORAGE               3   0  1  33 hda
b $STORAGE               3  64  1  33 hdb

b $STORAGE               4   0  1   1 root
l                                     systty tty0
c $TTY                   4   0  1  64 tty%d
c $SERIAL                4  64  1 192 ttyS%d

c $ALLWRITE              5   0  1   1 tty
c $CONSOLE               5   1  1   1 console
c $ALLWRITE              5   2  1   1 ptmx
c $SERIAL                5  64  1 192 cua%d

c $PRINTER               6   0  1   4 lp%d

c $VCSA                  7   0  1  64 vcs
c $VCSA                  7 128  1  64 vcsa

b $STORAGE               7   0  1 256 loop%d

b $STORAGE               8   0  1 256 sd%c%|%d a 16

c $STORAGE               9   0  1  32 st%d
c $STORAGE               9  32  1  32 st%dl
c $STORAGE               9  64  1  32 st%dm
c $STORAGE               9  96  1  32 st%da
c $STORAGE               9 128  1  32 nst%d
c $STORAGE               9 160  1  32 nst%dl
c $STORAGE               9 192  1  32 nst%dm
c $STORAGE               9 224  1  32 nst%da

b $STORAGE               9   0  1  32 md%d

c $CONSOLE              10   0  1   1 logibm
c $CONSOLE              10   1  1   1 psaux
c $CONSOLE              10   2  1   1 inportbm
c $CONSOLE              10   3  1   1 atibm
c $CONSOLE              10   4  1   1 jbm
c $CONSOLE              10  11  1   1 vrtpanel

# Where did 12 go?

c $CONSOLE              10  13  1   1 vpcmouse
c $CONSOLE              10  14  1   1 touchscreen/ucb1x00
c $CONSOLE              10  15  1   1 touchscreen/mk712

c $CONSOLE              10 128  1   1 beep
c $ROOT                 10 129  1   1 modreq
c $ROOT                 10 130  1   1 watchdog
c $ROOT                 10 131  1   1 temperature
c $ROOT                 10 132  1   1 hwtrap
c $ROOT                 10 133  1   1 exttrp
c $ROOT                 10 134  1   1 apm_bios
c $ALLREAD              10 135  1   1 rtc

# Where did 136, 137, and 138 go?

c $ROOT                 10 140  1   1 relay8
c $ROOT                 10 141  1   1 relay16
c $ROOT                 10 142  1   1 msr
c $ROOT                 10 143  1   1 pciconf
c $ROOT                 10 144  1   1 nvram
c $CONSOLE              10 146  1   1 graphics
c $CONSOLE              10 147  1   1 opengl
c $CONSOLE              10 148  1   1 gfx
c $CONSOLE              10 149  1   1 input/mouse
c $CONSOLE              10 150  1   1 input/keyboard
c $CONSOLE              10 151  1   1 led
c $ROOT                 10 152  1   1 kpoll
c $ROOT                 10 153  1   1 mergemem
c $SERIAL               10 155  1   1 isictl
c $ROOT                 10 156  1   1 lcd
c $ROOT                 10 157  1   1 ac
c $ROOT                 10 161  1   1 userdma
c $ROOT                 10 162  1   1 smbus
c $CONSOLE              10 163  1   1 lik
c $ROOT                 10 164  1   1 ipmo
c $SERIAL               10 168  1   1 tcldrv
c $ROOT                 10 172  1   1 usemaclone
c $ROOT                 10 173  1   1 ipmikcs
c $ROOT                 10 174  1   1 uctrl
c $ALLREAD              10 175  1   1 agpgart
c $ALLREAD              10 176  1   1 gtrsc
c $SERIAL               10 177  1   1 cbm
c $ROOT                 10 178  1   1 jsflash
c $ROOT                 10 179  1   1 xsvc
c $CONSOLE              10 180  1   1 vrbuttons
c $ROOT                 10 182  1   1 perfctr
c $ROOT                 10 183  1   1 hwrng

c $ROOT                 10 184  1   1 cpu/microcode

# Where did 185 go?

c $ROOT                 10 187  1   1 irnet
c $ROOT                 10 188  1   1 smbusbios
c $ROOT                 10 189  1   1 ussp_ctl
c $ROOT                 10 190  1   1 crash

# Where did 196 and 197 go?

c $ROOT                 10 200  1   1 net/tun

# Where did 203 go?

c $CONSOLE              10 204  1   1 video/em8300
c $CONSOLE              10 205  1   1 video/em8300_mv
c $CONSOLE              10 206  1   1 video/em8300_ma
c $CONSOLE              10 207  1   1 video/em8300_sp
c $ROOT                 10 208  1   1 compaq/cpqphpc
c $ROOT                 10 209  1   1 compaq/cpqrid
c $ROOT                 10 210  1   1 impi/bt
c $ROOT                 10 211  1   1 impi/smic
c $ROOT                 10 212  1   4 watchdogs/%d
c $ROOT                 10 216  1   1 fujitsu/apanel
c $ROOT                 10 217  1   1 ni/natmotn
c $ROOT                 10 218  1   1 kchuid
c $ROOT                 10 220  1   1 mptctl
c $ROOT                 10 223  1   1 input/uinput
c $ROOT                 10 224  1   1 tpm
c $ROOT                 10 225  1   1 pps
c $ROOT                 10 226  1   1 systrace
c $ROOT                 10 227  1   1 mcelog
c $ROOT                 10 228  1   1 hpet
c $ROOT                 10 229  1   1 fuse
c $ROOT                 10 230  1   1 midishare

# SPARC only
c $CONSOLE              11   0  1   1 kbd
# PA-RISC only
# c $SERIAL               11   0  1   4 ttyB%d
b $STORAGE              11   0  1  32 scd%d


b $STORAGE              12   0  1   8 dos_cd%d

c $CONSOLE              13   0  1  32 input/js%d
c $CONSOLE              13  32  1  31 input/mouse%d
c $CONSOLE              13  63  1   1 input/mice
c $CONSOLE              13  64  1  32 input/event%d

b $STORAGE              13   0  1 128 xd%c%|%d a 64

c $CONSOLE              14   0  1   1 mixer
c $CONSOLE              14   1  1   1 sequencer
c $CONSOLE              14   2  1   1 midi00
c $CONSOLE              14   3  1   1 dsp
c $CONSOLE              14   4  1   1 audio

# Where did 5 go?

c $CONSOLE              14   6  1   1 sndstat
c $CONSOLE              14   7  1   1 audioctl
c $CONSOLE              14   8  1   1 sequencer2

c $CONSOLE              14  16  1   1 mixer1
c $CONSOLE              14  17  1   1 patmgr0
c $CONSOLE              14  18  1   1 midi01
c $CONSOLE              14  19  1   1 dsp1
c $CONSOLE              14  20  1   1 audio1

c $CONSOLE              14  33  1   1 patmgr1
c $CONSOLE              14  34  1   1 midi02
c $CONSOLE              14  50  1   1 midi03

b $STORAGE              14   0  1  17 dos_hda
b $STORAGE              14  64  1  17 dos_hdb
b $STORAGE              14 128  1  17 dos_hdc
b $STORAGE              14 192  1  17 dos_hdd

l                                     js0 input/js0
l                                     js1 input/js1
l                                     js2 input/js2
l                                     js3 input/js3

# Replaced with symlinks to input core joystick devices (see usb).
#c $CONSOLE              15   0  1 128 js%d
#c $CONSOLE              15 128  1 128 djs%d


c $CONSOLE              16   0  1   1 gs4500

c $SERIAL               17   0  1  16 ttyH%d

c $SERIAL               18   0  1  16 cuh%d

c $SERIAL               19   0  1  33 ttyC%d
b $STORAGE              19   0  1   8 double%d
b $STORAGE              19 128  1   8 cdouble%d

c $SERIAL               20   0  1  32 cub%d
b $STORAGE              20   0  1   1 hitcd

c $STORAGE              21   0  1 256 sg%d
b $STORAGE              21   0  1  64 mfma
b $STORAGE              21  64  1  64 mfmb

c $SERIAL               22   0  1  32 ttyD%d
b $STORAGE              22   0  1  33 hdc
b $STORAGE              22  64  1  33 hdd

c $SERIAL               23   0  1  32 cud%d

c $SERIAL               24   0  1 256 ttyE%d

c $SERIAL               25   0  1 256 cue%d

c $CONSOLE              26   0  1   1 wvisfgrab

c $STORAGE              27   0  1   4 qft%d
c $STORAGE              27   4  1   4 nqft%d
c $STORAGE              27  16  1   4 zqft%d
c $STORAGE              27  20  1   4 nzqft%d
c $STORAGE              27  32  1   4 rawqft%d
c $STORAGE              27  36  1   4 nrawqft%d

c $PRINTER              28   0  1   4 slm%d

c $CONSOLE              29   0  1  32 fb%d

c $ROOT                 30   0  1   1 socksys
c $ROOT                 30   1  1   1 spx
c $ROOT                 30  32  1   1 inet/ip
c $ROOT                 30  33  1   1 inet/icmp
c $ROOT                 30  34  1   1 inet/ggp
c $ROOT                 30  35  1   1 inet/ipip
c $ROOT                 30  36  1   1 inet/tcp
c $ROOT                 30  37  1   1 inet/egp
c $ROOT                 30  38  1   1 inet/pup
c $ROOT                 30  39  1   1 inet/udp
c $ROOT                 30  40  1   1 inet/idp
c $ROOT                 30  41  1   1 inet/rawip
l                                     ip    inet/ip
l                                     icmp  inet/icmp
l                                     ggp   inet/ggp
l                                     ipip  inet/ipip
l                                     tcp   inet/tcp
l                                     egp   inet/egp
l                                     pup   inet/pup
l                                     udp   inet/udp
l                                     idp   inet/idp
l                                     rawip inet/rawip
l                                     inet/arp udp
l                                     inet/rip udp
l                                     nfsd socksys
l                                     X0R null


c $CONSOLE              31   0  1   1 mpu401data
c $CONSOLE              31   1  1   1 mpu401stat
b $STORAGE              31   0  1   8 rom%d
b $STORAGE              31   8  1   8 rrom%d
b $STORAGE              31  16  1   8 flash%d
b $STORAGE              31  24  1   8 rflash%d

c $SERIAL               32   0  1  16 ttyX%d

c $SERIAL               33   0  1  16 cux%d
b $STORAGE              33   0  1  33 hde
b $STORAGE              33  64  1  33 hdf

c $ROOT                 34   0  1  16 scc%d
b $STORAGE              34   0  1  33 hdg
b $STORAGE              34  64  1  33 hdh

c $CONSOLE              35   0  1   4 midi%d
c $CONSOLE              35  64  1   4 rmidi%d
c $CONSOLE              35 128  1   4 smpte%d
b $STORAGE              35   0  1   1 slram

c $ROOT                 36   0  1   1 route
c $ROOT                 36   1  1   1 skip
c $ROOT                 36   2  1   1 fwmonitor
c $ROOT                 36  16  1  16 tap%d
b $STORAGE              36   0  1  64 eda
b $STORAGE              36  64  1  64 edb

c $STORAGE              37   0  1 128 ht%d
c $STORAGE              37 128  1 128 nht%d
b $STORAGE              37   0  1   1 z2ram

c $ROOT                 38   0  1  16 mlanai%d

c $ROOT                 39   0  1  16 ml16pa-a%d
c $ROOT                 39  16  1   1 ml16pa-d
c $ROOT                 39  17  1   3 ml16pa-c%d
c $ROOT                 39  32  1  16 ml16pb-a%d
c $ROOT                 39  48  1   1 ml16pb-d
c $ROOT                 39  49  1   3 ml16pb-c%d

c $CONSOLE              40   0  1   1 mmetfgrab

c $ROOT                 41   0  1   1 yamm

# Stay away from major 42!  Don't add any entries which use it!  I mean it!

c $SERIAL               43   0  1  64 ttyI%d
b $STORAGE              43   0  1 128 nb%d


c $SERIAL               44   0  1  64 cui%d
c $ROOT                 45 128  1  64 ippp%d
c $ROOT                 45 255  1   1 isdninfo
b $STORAGE              45   0  1  64 pd%c%|%d a 16

c $SERIAL               46   0  1  16 ttyR%d
b $STORAGE              46   0  1   4 pcd%d

c $SERIAL               47   0  1  16 cur%d
b $STORAGE              47   0  1   4 pf%d

c $SERIAL               48   0  1  16 ttyL%d
c $SERIAL               49   0  1  16 cul%d

c $SERIAL               51   0  1  16 bc%d

c $ROOT                 52   0  1   4 dcbri%d

c $ROOT                 53   0  1   3 pd_bdm%d

c $SERIAL               54   0  1   3 holter%d


c $ROOT                 56   0  1   1 adb
b $STORAGE              56   0  1  33 hdi
b $STORAGE              56  64  1  33 hdj

c $SERIAL               57   0  1  16 ttyP%d
b $STORAGE              57   0  1  33 hdk
b $STORAGE              57  64  1  33 hdl

c $SERIAL               58   0  1  16 cup%d

c $ROOT                 59   0  1   1 firewall

# Here there be dragons.

c $ROOT                 64   0  1   1 enskip
b $STORAGE              64   0  1   1 scramdisk/master
b $STORAGE              64   1  1 254 scramdisk/%d

c $ROOT                 65   0  1   4 plink%d
c $ROOT                 65  64  1   4 rplink%d
c $ROOT                 65 128  1   4 plink%dd
c $ROOT                 65 192  1   4 rplink%dd

c $ROOT                 66   0  1  16 yppcpci%d
c $STORAGE              67   0  1   1 cfs0
c $ROOT                 68   0  1   1 capi20
c $ROOT                 68   1  1  20 capi20.%02d
c $ROOT                 69   0  1   1 ma16
c $ROOT                 70   0  1   1 apscfg
c $ROOT                 70   1  1   1 apsauth
c $ROOT                 70   2  1   1 apslog
c $ROOT                 70   3  1   1 apsdbg
c $ROOT                 70  64  1   1 apsisdn
c $ROOT                 70  65  1   1 apsasync
c $ROOT                 70 128  1   1 apsmon
c $SERIAL               71   0  1 256 ttyF%d
c $SERIAL               72   0  1 256 cuf%d

c $ROOT                 73   0  4   4 ip2ipl%d
c $ROOT                 73   1  4   4 ip2stat%d

c $ROOT                 74   0  1  16 SCI/%d

c $SERIAL               75   0  1  16 ttyW%d

c $SERIAL               76   0  1  16 cuw%d

c $ALLREAD              77   0  1   1 qng


c $CONSOLE              80   0  1   1 at200

c $CONSOLE              81   0  1  64 video%d
c $CONSOLE              81  64  1  64 radio%d
c $CONSOLE              81 192  1  32 vtx%d
c $CONSOLE              81 224  1  32 vbi%d

c $ROOT                 84   0  1   2 ihcp%d

c $ROOT                 85   0  1   1 shmiq
c $ROOT                 85   1  1   8 qcntl%d


c $STORAGE              86   0  1   8 sch%d

c $STORAGE              87   0  1   8 controla%d


c $SERIAL               88   0  1   8 comx%d

b $STORAGE              88   0  1  33 hdm
b $STORAGE              88  64  1  33 hdn

c $ROOT                 89   0  1   8 i2c-%d

b $STORAGE              89   0  1  33 hdo
b $STORAGE              89  64  1  33 hdp

c $STORAGE              90   0  2  16 mtd%d
c $STORAGE              90   1  2  16 mtdr%d

b $STORAGE              90   0  1  33 hdq
b $STORAGE              90  64  1  33 hdr

c $ROOT                 91   0  1  16 can%d

b $STORAGE              91   0  1  33 hds
b $STORAGE              91  64  1  33 hdt

b $STORAGE              92   0  1  64 ppdd%d

c $CONSOLE              93   0  1   8 iscc%d
c $CONSOLE              93 128  1   8 isccctl%d

b $STORAGE              93   0 16   1 nftla
b $STORAGE              93  16 16  15 nftl%c a

c $CONSOLE              94   0  1   8 dcxx%d


c $ROOT                 95   0  1   1 ipl
c $ROOT                 95   1  1   1 ipnat
c $ROOT                 95   2  1   1 ipstate
c $ROOT                 95   3  1   1 ipauth

c $STORAGE              96   0  1  16 pt%d
c $STORAGE              96 128  1  16 npt%d

c $STORAGE              97   0  1   4 pg%d

c $ROOT                 98   0  1   4 comedi%d

b $STORAGE              98   0  1 256 ubd%c%|%d a 16

c $PRINTER              99   0  1   8 parport%d
b $STORAGE              99   0  1   1 jsfd

c $CONSOLE             100   0  1   8 phone%d

c $ROOT                101   0  1   1 mdspstat
c $ROOT                101   1  1  16 mdsp%d 1

c $ROOT                102   0  1   4 tlk%d

b $STORAGE             102   0  1 256 cbd/%c%|%d a 16

c $STORAGE             103   0  1   2 nnpfs%d
b $ROOT                103   0  1   1 audit

c $SERIAL              105   0  1  16 ttyV%d

c $SERIAL              106   0  1  16 cuv%d

c $CONSOLE             107   0  1   1 3dfx

c $ROOT                108   0  1   1 ppp

c $CONSOLE             110   0  1   8 srnd%d

c $CONSOLE             111   0  1   8 av%d

c $SERIAL              112   0  1  16 ttyM%x


c $SERIAL              113   0  1  16 cum%d


c $ROOT                114   0  1  16 ise%d
c $ROOT                114 128  1  16 isex%d

c $PRINTER             115   0  1   8 tipar%d
c $SERIAL              115   8  1   8 tiser%d
c $ROOT                115  16  1  16 tiusb%d

c $SERIAL              117   0  1  16 cosa0c%d
c $SERIAL              117  16  1  16 cosa1c%d

c $ROOT                118   0  1   1 ica
c $ROOT                118   1  1  15 ica%d

c $ROOT                119   0  1  10 vnet%d


c $ROOT                144   0  1  64 pppox%d

c $CONSOLE             145   0 64   4 sam%d_mixer
c $CONSOLE             145   1 64   4 sam%d_sequencer
c $CONSOLE             145   2 64   4 sam%d_midi00
c $CONSOLE             145   3 64   4 sam%d_dsp
c $CONSOLE             145   4 64   4 sam%d_audio
c $CONSOLE             145   6 64   4 sam%d_sndstat
c $CONSOLE             145  18 64   4 sam%d_midi01
c $CONSOLE             145  34 64   4 sam%d_midi02
c $CONSOLE             145  50 64   4 sam%d_midi03

c $ROOT                146   0  1   8 scramnet%d
c $CONSOLE             147   0  1   8 aureal%d

b $STORAGE             147   0  1   8 drbd%d

c $SERIAL              148   0  1  16 ttyT%d
c $SERIAL              149   0  1  16 cut%d

c $ROOT                150   0  1  16 rtf%d

c $STORAGE             151   0  1  16 dpti%d

c $STORAGE             152   0  1   1 etherd/ctl
c $STORAGE             152   1  1   1 etherd/err
c $STORAGE             152   2  1   1 etherd/raw

b $STORAGE             152   0  1 256 etherd/%d

c $ROOT                153   0  1  16 spi/spi%d

c $SERIAL              154   0  1 256 ttySR%d
c $SERIAL              155   0  1 256 cusr%d
c $SERIAL              156   0  1 256 ttySR%d 256
c $SERIAL              157   0  1 256 cusr%d  256

c $SERIAL              158   0  1  16 gfax%d

c $ROOT                160   0  1  16 gpib%d


c $SERIAL              161   0  1  16 ircomm%d
c $PRINTER             161  16  1  16 irlpt%d

c $STORAGE             162   0  1   1 rawctl
c $STORAGE             162   1  1 255 raw/raw%d 1

c $SERIAL              163   0  1  64 bimrt%d

c $SERIAL              164   0  1  64 ttyCH%d
c $SERIAL              165   0  1  64 cuch%d

# Moved to the input subdirectory (see usb).
#c $SERIAL              166   0  1  16 ttyACM%d
#c $SERIAL              167   0  1  16 cuacm%d

c $ROOT                168   0  1  64 ecsa%d
c $ROOT                169   0  1  64 ecsa8-%d

c $ROOT                170   0  1  64 megarac%d

# 171 is used by various ieee1394 drivers.  See http://www.linux1394.org/ for
# more information.

c $SERIAL              172   0  1 128 ttyMX%d
c $SERIAL              172 128  1   1 moxactl
c $SERIAL              173   0  1 128 cumx%d

c $SERIAL              174   0  1  16 ttySI%d
c $SERIAL              175   0  1  16 cusi%d

c $ROOT                176   0  1  16 nfastpci%d

c $ROOT                177   0  1  16 pcilynx/aux%d
c $ROOT                177  16  1  16 pcilynx/rom%d
c $ROOT                177  32  1  16 pcilynx/ram%d

c $ROOT                178   0  1  16 clanvi%d

c $CONSOLE             179   0  1  16 dvxirq%d

c $PRINTER             180   0  1  16 usb/lp%d
c $CONSOLE             180  48  1  16 usb/scanner%d
c $CONSOLE             180  64  1   1 usb/rio500
c $ROOT                180  65  1   1 usb/usblcd
c $ROOT                180  66  1   1 usb/cpad0
c $CONSOLE             180  96  1  16 usb/hiddev%d
c $ROOT                180 112  1  16 usb/auer%d
c $ROOT                180 128  1   4 usb/brlvgr%d
c $ROOT                180 132  1   1 usb/idmouse
c $ROOT                180 133  1   8 usb/sisusbvga%d 1
c $ROOT                180 144  1   1 usb/lcd
c $ROOT                180 160  1  16 usb/legousbtower%d
c $ROOT                180 240  1   4 usb/dabusb%d

c $ALLREAD             181   0  1  16 pcfclock%d
c $ROOT                182   0  1  16 pethr%d

c $ROOT                183   0  1  16 ss5136dn%d
c $ROOT                184   0  1  16 pevss%d
c $STORAGE             185   0  1  16 intermezzo%d
c $ROOT                186   0  1  16 obd%d
c $ROOT                187   0  1  16 deskey%d

c $SERIAL              188   0  1  16 ttyUSB%d
c $SERIAL              189   0  1  16 cuusb%d

c $CONSOLE             190   0  1  16 kctt%d

c $ROOT                192   0  1   1 profile
c $ROOT                192   1  1  16 profile%d
c $ROOT                193   0  1   1 trace
c $ROOT                193   1  1  16 trace%d

c $CONSOLE             194   0 16  16 mvideo/status%d
c $CONSOLE             194   1 16  16 mvideo/stream%d
c $CONSOLE             194   2 16  16 mvideo/frame%d
c $CONSOLE             194   3 16  16 mvideo/rawframe%d
c $CONSOLE             194   4 16  16 mvideo/codec0%d
c $CONSOLE             194   5 16  16 mvideo/video4linux%d

c $ROOT                196   0  1  51 tor/%d

c $ROOT                197   0  1 128 tnf/t%d
c $ROOT                197 128  1   1 tnf/status
c $ROOT                197 130  1   1 tnf/trace

c $ROOT                198   0  1   8 tpmp2/%d

# We can skip 199 because Veritas user-land handles it.



c $ROOT                202   0  1  16 cpu/%d/msr


c $ROOT                203   0  1  16 cpu/%d/cpuid

b $ROOT                203   0  1  16 cpu/%d/cpuid

c $SERIAL              204   0  1   4 ttyLU%d
c $SERIAL              204   4  1   1 ttyFB%d
c $SERIAL              204   5  1   3 ttySA%d
c $SERIAL              204   8  1   4 ttySC%d
c $SERIAL              204  12  1   4 ttyFW%d
c $SERIAL              204  16  1  16 ttyAM%d
c $SERIAL              204  32  1   8 ttyDB%d
c $TTY                 204  40  1   1 ttySG0
c $SERIAL              204  41  1   3 ttySMX%d
c $SERIAL              204  44  1   2 ttyMM%d
c $SERIAL              204  46  1   4 ttyCPM%d
c $SERIAL              204  50  1  32 ttyIOC%d
c $SERIAL              204  82  1   2 ttyVR%d
c $SERIAL              204  84  1  32 ttyIOC%d 84
c $SERIAL              204 116  1  32 ttySIOC%d
c $SERIAL              204 148  1   6 ttyPSC%d
c $SERIAL              204 154  1  16 ttyAT%d
c $SERIAL              204 170  1  16 ttyNX%d
c $SERIAL              204 186  1   1 ttyJ0

c $SERIAL              205   0  1   4 culu%d
c $SERIAL              205   4  1   1 cufb%d
c $SERIAL              205   5  1   3 cusa%d
c $SERIAL              205   8  1   4 cusc%d
c $SERIAL              205  12  1   4 cufw%d
c $SERIAL              205  16  1  16 cuam%d
c $SERIAL              205  32  1   8 cudb%d
c $TTY                 205  40  1   1 cusg0
c $SERIAL              205  41  1   3 ttycusmx%d
c $SERIAL              205  44  1   5 cucpm%d
c $SERIAL              205  50  1  32 cuioc4%d
c $SERIAL              205  82  1   2 cuvr%d

c $STORAGE             206   0  1  32 osst%d
c $STORAGE             206  32  1  32 osst%dl
c $STORAGE             206  64  1  32 osst%dm
c $STORAGE             206  96  1  32 osst%da
c $STORAGE             206 128  1  32 nosst%d
c $STORAGE             206 160  1  32 nosst%dl
c $STORAGE             206 196  1  32 nosst%dm
c $STORAGE             206 224  1  32 nosst%da

c $SERIAL              208   0  1 256 ttyU%d
c $SERIAL              209   0  1 256 cuu%d

c $SERIAL              210   0 10   4 sbei/wxcfg%d
c $SERIAL              210   1 10   4 sbei/dld%d
c $SERIAL              210   2  1   4 sbei/wan0%d
c $SERIAL              210   6  1   4 sbei/wanc0%d
c $SERIAL              210  12  1   4 sbei/wan1%d
c $SERIAL              210  16  1   4 sbei/wanc1%d
c $SERIAL              210  22  1   4 sbei/wan2%d
c $SERIAL              210  26  1   4 sbei/wanc2%d
c $SERIAL              210  32  1   4 sbei/wan3%d
c $SERIAL              210  36  1   4 sbei/wanc3%d

c $SERIAL              211   0  1   8 addinum/cpci1500/%d

c $ROOT                212   0  9   7 dvb/adapter0/video%d
c $ROOT                212   1  9   7 dvb/adapter0/audio%d
c $ROOT                212   2  9   7 dvb/adapter0/sec%d
c $ROOT                212   3  9   7 dvb/adapter0/frontend%d
c $ROOT                212   4  9   7 dvb/adapter0/demux%d
c $ROOT                212   5  9   7 dvb/adapter0/dvr%d
c $ROOT                212   6  9   7 dvb/adapter0/ca%d
c $ROOT                212   7  9   7 dvb/adapter0/net%d
c $ROOT                212   8  9   7 dvb/adapter0/osd%d
c $ROOT                212  64  9   7 dvb/adapter1/video%d
c $ROOT                212  65  9   7 dvb/adapter1/audio%d
c $ROOT                212  66  9   7 dvb/adapter1/sec%d
c $ROOT                212  67  9   7 dvb/adapter1/frontend%d
c $ROOT                212  68  9   7 dvb/adapter1/demux%d
c $ROOT                212  69  9   7 dvb/adapter1/dvr%d
c $ROOT                212  70  9   7 dvb/adapter1/ca%d
c $ROOT                212  71  9   7 dvb/adapter1/net%d
c $ROOT                212  72  9   7 dvb/adapter1/osd%d
c $ROOT                212 128  9   7 dvb/adapter2/video%d
c $ROOT                212 129  9   7 dvb/adapter2/audio%d
c $ROOT                212 130  9   7 dvb/adapter2/sec%d
c $ROOT                212 131  9   7 dvb/adapter2/frontend%d
c $ROOT                212 132  9   7 dvb/adapter2/demux%d
c $ROOT                212 133  9   7 dvb/adapter2/dvr%d
c $ROOT                212 134  9   7 dvb/adapter2/ca%d
c $ROOT                212 135  9   7 dvb/adapter2/net%d
c $ROOT                212 136  9   7 dvb/adapter2/osd%d
c $ROOT                212 192  9   7 dvb/adapter3/video%d
c $ROOT                212 193  9   7 dvb/adapter3/audio%d
c $ROOT                212 194  9   7 dvb/adapter3/sec%d
c $ROOT                212 195  9   6 dvb/adapter3/frontend%d
c $ROOT                212 196  9   6 dvb/adapter3/demux%d
c $ROOT                212 197  9   6 dvb/adapter3/dvr%d
c $ROOT                212 198  9   6 dvb/adapter3/ca%d
c $ROOT                212 199  9   6 dvb/adapter3/net%d
c $ROOT                212 200  9   6 dvb/adapter3/osd%d

c $SERIAL              216   0  1  16 rfcomm%d
c $SERIAL              217   0  1  16 curf%d

c $ROOT                218   0  1  16 logicalco/bci/%d
c $ROOT                219   0  1  16 logicalco/dci1300/%d

c $ROOT                220   0  2  16 myricom/gm%d
c $ROOT                220   1  2  16 myricom/gmp%d

c $ROOT                221   0  1   4 bus/vme/m%d
c $ROOT                221   4  1   4 bus/vme/s%d
c $ROOT                221   8  1   1 bus/vme/ctl

c $SERIAL              224   0  1 255 ttyY%d
c $SERIAL              225   0  1 255 cuy%d

c $CONSOLE             226   0  1   4 dri/card%d

c $ROOT                227   1  1  32 3270/tty%d 1
c $ROOT                228   0  1  33 3270/tub

c $ROOT                229   0  1  32 iseries/vtty%d

c $ROOT                232   0 10   3 biometric/sensor%d/fingerprint
c $ROOT                232   1 10   3 biometric/sensor%d/iris
c $ROOT                232   2 10   3 biometric/sensor%d/retina
c $ROOT                232   3 10   3 biometric/sensor%d/voiceprint
c $ROOT                232   4 10   3 biometric/sensor%d/facial
c $ROOT                232   5 10   3 biometric/sensor%d/hand

c $ROOT                233   0  1   1 ipath
c $ROOT                233   1  1   4 ipath%d
c $ROOT                233 129  1   1 ipath_sma
c $ROOT                233 130  1   1 ipath_diag

c $ROOT                256   0  1 1028 ttyEQ%d

b $ROOT                256   0  1 256 rfd%c%|%d a 16

c $ROOT                257   0  1   1 ptlsec
