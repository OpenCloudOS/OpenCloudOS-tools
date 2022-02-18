select /dev/${INSDISK}
mklabel gpt
unit MiB
mkpart primary ext2 1 22009
mkpart primary fat32 22009 22521
mkpart primary ext2 22521 43001
mkpart primary ext2 43001 -1
set 2 boot on
quit
