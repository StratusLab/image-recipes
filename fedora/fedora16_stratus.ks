# This kickstart allows to do base installation of Fedora 16 x86_64 with
# contextualisation scripts for StratusLab.

install
text
#url --url http://download.fedoraproject.org/pub/fedora/linux/releases/14/Everything/x86_64/os/
url  --url http://mirrors.ircam.fr/pub/fedora/linux/releases/16/Everything/x86_64/os/
#url  --url http://quattorsrv.lal.in2p3.fr/packages/os/fedora14-x86_64/base/
#repo --name=Quattor    --baseurl=http://quattorsrv.lal.in2p3.fr/packages/os/fedora14-x86_64/updates/
#repo --name=StratusLab --baseurl=http://quattorsrv.lal.in2p3.fr/packages/stratuslab/
repo  --name=StratusLab --baseurl=http://yum.stratuslab.eu/snapshots/fedora14/
lang en_US.UTF-8
keyboard us
network --onboot yes --device eth0 --bootproto dhcp 
timezone --utc Etc/UTC
firstboot --disabled

selinux --disabled
firewall --disabled 

rootpw --iscrypted $1$eCTgMV06$qUhgnyawari7MKalTAxZj1
#authconfig --enableshadow --passalgo=sha512 --enablefingerprint
auth --enableshadow --enablemd5


# Deleting the old partitions
clearpart --all --drives=sda
zerombr

# Creating the new partitions
part biosboot --fstype=biosboot --size=1
part /boot --fstype=ext3        --ondisk=sda --asprimary
part /     --fstype=ext4 --grow --ondisk=sda --asprimary
bootloader --location=mbr --driveorder=sda --append="norhgb quiet vga=792"
#ignoredisk --drives=sdb


# Installing packages
%packages
#@admin-tools
@base
@core
#@editors
#@fonts
#@gnome-desktop
#@games
#@graphical-internet
#@graphics
@hardware-support
#@input-methods
#@java
#@office
#@online-docs
#@printing
#@sound-and-video
@text-internet
#@base-x
xfsprogs
#mtools
#gpgme
#openoffice.org-opensymbol-fonts
#gvfs-obexftp
#hdparm
#gok
#iok
#vorbis-tools
#jack-audio-connection-kit
#ncftp
#gdm
openssh
openssh-server
openssh-clients
stratuslab-one-context
%end

# Post installation scripts
%post
# Set the cdrom block device to use for contextualisation
sed -i 's/context_device.*$/context_device=sr0/' /etc/stratuslab/stratuslab-one-context.cfg
# Remove any occurences of the mac address
rm /etc/udev/rules.d/70-persistent-*.rules
sed -i 's/HWADDR.*$//' /etc/sysconfig/network-scripts/ifcfg-eth0
# Add sdb swap disk in the fstab
echo "/dev/sdb swap swap defaults 0 0" >> /etc/fstab

#
# Ensure that all packages are up-to-date.
#
yum upgrade -y 

%end

# Reboot after installation
reboot
