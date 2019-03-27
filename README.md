# Preparations
Basically all you need (other than git) are basic build tools. These are contained in base-devel. The good news is that the build script will install/update them automaticallly using pacman.
Additionally installing ccache will speed compilation up by a lot. (Well - the first one will be pretty slow, but every further one will be pretty fast.)

# Installation
Couterarch was designed for installation on a clean arch linux. It is actually pretty simple to install.

1. Run buid.sh and follow the instructions
2. If you (understandably) didn't chose to let Counterarch update your bootloader config, you will need to do this manually (for example grub-mkconfig -o /boot/grub/grub.cfg)

# Updating
Updating your counterarch kernel is pretty simple. Just rerun build.sh and follow the instructions ;)

