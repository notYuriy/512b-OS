rm -rf boot
nasm boot.s -o boot
rm -rf os.vfd
./fat_imgen -c -f os.vfd -F -s boot
for name in initdisk/*; do
    ./fat_imgen -m -f os.vfd -i  $name
done
