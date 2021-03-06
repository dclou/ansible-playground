#!/bin/sh
set -x
parted /dev/sda mklabel msdos || true
parted /dev/sda mkpart primary 0% 100% || true
mkfs.ext4 /dev/sda1
mount /dev/sda1 /mnt
mkdir -p /mnt/etc/clusterconf
curl http://${1}/conf/$(hostname -s).tar.gz | tar -xzvf - -C /mnt/etc/clusterconf
echo "Server = http://mirror.yandex.ru/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
pacstrap /mnt base grub openssh python sudo docker openbsd-netcat git
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt grub-install /dev/sda
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
arch-chroot /mnt groupadd -r sudo
arch-chroot /mnt useradd -m -G sudo,docker user
echo "%sudo ALL=(ALL) NOPASSWD: ALL" > /mnt/etc/sudoers.d/sudogroup
cp -aR /mnt/etc/clusterconf/* /mnt/etc/
mkdir -p /mnt/home/user/.ssh
cp /mnt/etc/authorized_keys /mnt/home/user/.ssh/authorized_keys
arch-chroot /mnt chown -R user:user /home/user
arch-chroot /mnt sh -c 'echo "HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub" >> /etc/ssh/sshd_config'
cp /etc/systemd/system/post-install.service /mnt/etc/systemd/system/post-install.service
arch-chroot /mnt systemctl enable post-install
arch-chroot /mnt systemctl enable sshd
arch-chroot /mnt systemctl enable systemd-networkd
arch-chroot /mnt systemctl enable systemd-resolved
echo -e "[Match]\nName=en*\n[Network]\nDHCP=ipv4" > /mnt/etc/systemd/network/basic.network
umount /mnt
sync
nc -l -p 50001
