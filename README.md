# baremetal_diskimage
baremetal_diskimage is a vagrant(virtualbox) environment to make baremetal disk image.
This disk image supports both UEFI and BIOS environments, and GRUB2 boot loader is installed on it.

## Dependencies
- [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- [Vagrant](https://www.vagrantup.com/downloads.html)

Do not install them via package manager (apt, yum, etc...).
Please download and install the latest version from the official website.

## Setup
To make the disk image, simply run:
```
$ ./setup.sh
```
