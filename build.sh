#! /bin/bash
LATESTSTABLE="v4.19"

cat<<LOGOEOF
  #         ####         #
 #         ######         #
#         ###  ###         #
#        ###    ###        #
#       ###      ###       #
#      ###        ###      #
 #    ###   /''    ###    #
  #  ###    \..     ###  #

CounterArch kernel updater - driven by bad ideas.
====================================================
LOGOEOF
echo Performing pacman updates...
sudo pacman -Sy
sudo pacman -S base-devel --noconfirm --needed

cd linux
if [ ! -f .config ]; then
    echo Performing first time setup...
    zcat /proc/config.gz > .config
    make prepare
fi;
set -e
read -p "Use the master branch? (y/N)" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\e[31mWarning: \e[39mThis will actually update your kernel to the current master branch. You should not do this."
    git remote update
    echo Reseting...
    git reset --hard $LOCAL
    git checkout master
    UPSTREAM=${1:-'@{u}'}
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse "$UPSTREAM")
    git pull
else
    echo Reseting...
    git reset --hard $LOCAL
    echo Updating to $LATESTSTABLE.
    git checkout tags/$LATESTSTABLE
    LOCAL=$(git describe --tags)
    REMOTE=$LATESTSTABLE
fi;

echo Checking for updates...
CURRENTKERNEL=$(uname -r)
NEWKERNEL=$(make kernelrelease)

if [ $LOCAL = $REMOTE ] && [ $CURRENTKERNEL = $NEWKERNEL ]; then
    echo No updates found. Exiting.
    exit 0
fi

echo Updates found.
read -p "Are you REALLY sure you want to do this? (y/N)" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo You have made the right decision.
    exit 1
fi

read -p "Apply ClearLinux? (y/N)" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git -C ../patchsets/ClearLinux checkout master
    git -C ../patchsets/ClearLinux pull
    set +e
    for i in ../patchsets/ClearLinux/*.patch; do
        echo Applying $i
        patch -f -p1 < $i
    done
    set -e
fi;

echo Hacking Makefiles to enable the whole instruction set...
sed -i -e 's/-march=core2/-march=native/g' arch/x86/Makefile
sed -i -e 's/-march=atom/-march=native/g' arch/x86/Makefile
echo Copying resources to base...
make clean
zcat /proc/config.gz > .config
make nconfig
make CC="ccache gcc" -j$(nproc --all)
read -p "Press enter to install the kernel modules"
sudo make modules_install

if [ -f /boot/vmlinuz-linux-counterarch ]; then
    read -p "Press enter to back up the old kernel"
    sudo cp -v /boot/vmlinuz-linux-counterarch /boot/vmlinuz-linux-counterarch-previous
    sudo cp -v /boot/initramfs-linux-counterarch.img /boot/initramfs-linux-counterarch-previous.img
fi

read -p "Press enter to install new kernel"
sudo cp -v arch/x86_64/boot/bzImage /boot/vmlinuz-linux-counterarch

if [ ! -f /etc/mkinitcpio.d/linux-counterarch.preset ]; then
    sudo cp -v ../linux-counterarch.preset /etc/mkinitcpio.d/
fi

sudo mkinitcpio -p linux-counterarch
read -p "Press enter to reinstall kernel modules"
sudo dkms autoinstall -k $(make kernelrelease)
echo Done.
