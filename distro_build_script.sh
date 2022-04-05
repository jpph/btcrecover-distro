#sudo su

add-apt-repository universe
apt-get update
apt-get install -y \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
    unzip

rm -rf $HOME/LIVE_BOOT
mkdir  $HOME/LIVE_BOOT

debootstrap \
    --arch=amd64 \
    --variant=minbase \
    bullseye \
    $HOME/LIVE_BOOT/chroot \
    http://ftp.de.debian.org/debian/

pushd .
cd /$HOME/LIVE_BOOT/chroot/root
wget -q https://github.com/3rdIteration/btcrecover/archive/master.zip
unzip master.zip
popd

cat << EOF >$HOME/LIVE_BOOT/chroot/chroot.sh
echo "btcrecoverdistro" > /etc/hostname;
echo "btcrecoverdistro 127.0.0.1" > /etc/hosts;
apt-get update;
apt-get install -y  \
    linux-image-amd64 \
    live-boot \
    systemd-sysv\
    xserver-xorg-core \
    xserver-xorg \
    xinit \
    vim \
    nano \
    xterm \
    python3-tk \
    python3-pip;
apt-get -y clean autoclean;

cd /root/btcrecover-master
pip3 install -r requirements.txt


echo "exec xterm " > /root/.xinitrc;
echo "cd btcrecover-master" >> /root/.profile;
chmod +x /root/.xinitrc;


cat << EOFrc > /etc/rc.local
#!/bin/sh -e
/bin/su root -l -c xinit -- VT08
exit 0
EOFrc
chmod +x /etc/rc.local

rm -rf /lib/modules/**/kernel/net
rm -rf /var/lib/{apt,dpkg,cache,log}/
rm -rf /usr/share/man
rm -rf /usr/share/doc
rm -rf /usr/share/icons
rm -rf /usr/share/locale

echo 'root:toor' | chpasswd

EOF

chmod +x $HOME/LIVE_BOOT/chroot/chroot.sh
chroot $HOME/LIVE_BOOT/chroot /chroot.sh

rm -r $HOME/LIVE_BOOT/{scratch,image/live}
mkdir -p $HOME/LIVE_BOOT/{scratch,image/live}

mksquashfs \
    $HOME/LIVE_BOOT/chroot \
    $HOME/LIVE_BOOT/image/live/filesystem.squashfs \
    -e boot;

cp $HOME/LIVE_BOOT/chroot/boot/vmlinuz-* \
    $HOME/LIVE_BOOT/image/vmlinuz && \
cp $HOME/LIVE_BOOT/chroot/boot/initrd.img-* \
    $HOME/LIVE_BOOT/image/initrd


cat << EOF >$HOME/LIVE_BOOT/scratch/grub.cfg

search --set=root --file /DEBIAN_CUSTOM

set default="0"
set timeout=0

menuentry "AirGap Distro" {
    linux /vmlinuz boot=live quiet nomodeset
    initrd /initrd
}
EOF

touch $HOME/LIVE_BOOT/image/DEBIAN_CUSTOM


grub-mkstandalone \
    --format=x86_64-efi \
    --output=$HOME/LIVE_BOOT/scratch/bootx64.efi \
    --locales="" \
    --fonts="" \
    "boot/grub/grub.cfg=$HOME/LIVE_BOOT/scratch/grub.cfg";

(cd $HOME/LIVE_BOOT/scratch && \
    dd if=/dev/zero of=efiboot.img bs=1M count=10 && \
    mkfs.vfat efiboot.img && \
    mmd -i efiboot.img efi efi/boot && \
    mcopy -i efiboot.img ./bootx64.efi ::efi/boot/
)

grub-mkstandalone \
    --format=i386-pc \
    --output=$HOME/LIVE_BOOT/scratch/core.img \
    --install-modules="linux normal iso9660 biosdisk memdisk search tar ls" \
    --modules="linux normal iso9660 biosdisk search" \
    --locales="" \
    --fonts="" \
    "boot/grub/grub.cfg=$HOME/LIVE_BOOT/scratch/grub.cfg"

cat \
    /usr/lib/grub/i386-pc/cdboot.img \
    $HOME/LIVE_BOOT/scratch/core.img \
> $HOME/LIVE_BOOT/scratch/bios.img

sleep 10

xorriso \
    -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "DEBIAN_CUSTOM" \
    -eltorito-boot \
        boot/grub/bios.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --eltorito-catalog boot/grub/boot.cat \
    --grub2-boot-info \
    --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -eltorito-alt-boot \
        -e EFI/efiboot.img \
        -no-emul-boot \
    -append_partition 2 0xef ${HOME}/LIVE_BOOT/scratch/efiboot.img \
    -output "/vagrant/btcrecover-distro.iso" \
    -graft-points \
        "${HOME}/LIVE_BOOT/image" \
        /boot/grub/bios.img=$HOME/LIVE_BOOT/scratch/bios.img \
        /EFI/efiboot.img=$HOME/LIVE_BOOT/scratch/efiboot.img

