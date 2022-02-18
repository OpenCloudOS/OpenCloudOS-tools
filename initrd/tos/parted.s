select /dev/${INSDISK}
mklabel msdos
unit MiB
mkpart primary ext2 1 20481
mkpart primary linux-swap 20481 22521
mkpart primary ext2 22521 43001
mkpart primary ext2 43001 -1
set 1 boot on
quit
