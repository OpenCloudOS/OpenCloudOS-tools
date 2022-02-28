select /dev/sda
mklabel gpt
unit MiB
mkpart primary fat32 1 513
mkpart primary ext2 513 -1
set 1 boot on
quit
