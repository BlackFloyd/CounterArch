#! /bin/bash
LATESTSTABLE="v5.0"
ROOT=$(pwd)
FIRST=false

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
echo Building from $ROOT
echo Performing pacman updates...
sudo pacman -Sy
sudo pacman -S base-devel --noconfirm --needed
sudo pacman -S wget --noconfirm --needed

cd linux
if [ ! -f .config ]; then
    FIRST=true
    echo Performing first time setup...
    zcat /proc/config.gz > .config
    make prepare
fi;
set -e
read -p "Use the master branch? (y/N)" -n 1 -r
echo
rm -rf net/wireguard ||:
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\e[31mWarning: \e[39mThis will actually update your kernel to the current master branch. You should not do this."
    git remote update
    echo Reseting...
    git reset --hard $LOCAL
    git checkout master
    git reset --hard origin/master
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

git clean -f
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
else
    read -p "Add WireGuard support? (y/N)" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git -C ../patchsets/WireGuard checkout master
        git -C ../patchsets/WireGuard pull
	"$ROOT/patchsets/WireGuard/contrib/kernel-tree/create-patch.sh" | patch -p1
    fi
fi

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
read -p "Reinstall previous kernel modules? (y/N)" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo dkms autoinstall -k $(make kernelrelease)
fi

if [FIRST -eq true]; then
    read -p "Perform grub-mkconfig? (y/N)" -n 1 -r
    if [[ $REPLY =~ ^ [Yy]$ ]]; then
        if [ ! -f /boot/grub/grub.cfg ]; then
            echo -e "\e[31mError: \e[39mI could not find your previous grub config under /boot/grub/grub.cfg. As this is the only compatible grub.cfg path I won't do anything. Please configure grub manually."
        else
            echo "Running grub-mkconfig..."
            grub-mkconfig -o /tmp/counterarch-grub.cfg
            read -p "Please press return and have a look at your new grub.cfg."
            ${EDITOR:-vi} /tmp/counterarch-grub.cfg
            read -p "Apply new config? (y/N)" -n 1 -r
            if [[ $REPLY =~ ^ [yY]$ ]]; then
                echo "Backing up old config to /boot/grub/grub.cfg.old"
                sudo cp /boot/grub/grub.cfg /boot/grub/grub.cfg.old
                echo "Applying new config..."
                sudo mv /tmp/counterarch-grub.cfg /boot/grub/grub.cfg
            fi
        fi
    fi
fi

echo Done.
