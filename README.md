# What is this?!
Good question. This is just a tool for quickly breaking your system. Well actually this tool allows you to quickly build a linux kernel using the master branch. Stable branch builds and patching is currently in progress - you can check out the development- and feature branches if you really like suffering.
This is definitely not suitable for any production use. It's purely a tool to make playing with the kernel more comfortable.

# Preparations
Basically all you need (other than git) are basic build tools. These are contained in base-devel.
Additionally installing ccache will speed compilation up by a lot. (Well - the first one will be pretty slow, but every further one will be pretty fast.)

# Installation
Couterarch was designed for installation on a clean arch linux. It is actually pretty simple to install. For more detailed instructions visit https://github.com/BlackFloyd/CounterArch/wiki/Installation

1. Run buid.sh and follow the instructions
2. Update your bootloaders config (for example grub-mkconfig -o /boot/grub/grub.cfg)

# Updating
Updating your counterarch kernel is pretty simple. Just rerun build.sh and follow the instructions ;)

