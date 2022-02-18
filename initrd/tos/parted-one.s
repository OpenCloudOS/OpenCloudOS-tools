select /dev/sda
mklabel msdos
unit MiB
mkpart primary ext2 1 -1
set 1 boot on
quit
