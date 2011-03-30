#!/bin/sh -x 


# Partition the disk image.  Creates a single primary partition
# using the full disk.
fdisk /dev/hda <<EOF
n
p
1


w
EOF


# Create an ext2 filesystem in the disk partition.  Note: the
# standard boot loader (lilo) cannot handle ext3 filesystems.
mkfs.ext2 /dev/hda1


# Copy the ttylinux system into the new filesystem.
ttylinux-installer -m /dev/hdc /dev/hda1 <<EOF
yes
yes
EOF


# Mount the new filesystem, so that changes can be made in the 
# default configuration. 
mount /dev/hda1 /mnt


# Remove the account "user" on the generated system.
chroot /mnt /bin/deluser user 


# Update the welcome files. 
dir=/mnt/etc
cat $dir/issue | sed /initial/d > $dir/issue.new 
cat >> $dir/issue.new <<EOF
Machine image prepared by the StratusLab Project (http://stratuslab.eu/)
EOF
mv $dir/issue.new $dir/issue

cat $dir/issue.tty | sed /initial/d > $dir/issue.tty.new
cat >> $dir/issue.tty.new <<EOF
Machine image prepared by the StratusLab Project (http://stratuslab.eu/)
EOF
mv $dir/issue.tty.new $dir/issue.tty


# Add a startup script to randomize the root password.  Do this
# before the network starts. 
dir=/mnt/etc/rc.d/rc.startup
cat > $dir/08.rndm-pswd <<EOS
#!/bin/sh
newpswd=\`cat /dev/urandom | tr -dc "a-zA-Z0-9-_\$\?" | head -c 8\`
passwd root <<EOF
\$newpswd
\$newpswd
EOF
EOS
chmod 0755 $dir/08.rndm-pswd


# Ensure that eth0 is enabled and configured for DHCP.
dir=/mnt/etc/sysconfig/network-scripts

cat $dir/ifcfg-eth0 | \
  sed s/ENABLE=no/ENABLE=yes/ | \
  sed s/DHCP=no/DHCP=yes/ > \
  $dir/ifcfg-eth0-new 

mv $dir/ifcfg-eth0-new $dir/ifcfg-eth0


# Comment out all lines for ports, except for ssh. 
# By default, ICMP (ping) requests are permitted.
dir=/mnt/etc
cat $dir/firewall.conf | \
  sed s/^tftp/\#tftp/ | \
  sed s/^ftp/\#ftp/ | \
  sed s/^http/\#http/ | \
  sed s/^1024:/\#1024:/ > \
  $dir/firewall.conf-new

# Move the firewall configuration into place.
mv $dir/firewall.conf-new $dir/firewall.conf


# Disallow password logins to the virtual machine and turn
# off the message of the day. 
cat >> /mnt/etc/sysconfig/ssh <<EOF
SSHD_OPTIONS=-msg
EOF


# Add the contextualization script. 
cat >> /mnt/usr/bin/onecontext <<EOF
#!/bin/sh -e
  
[ -e /dev/hdc ] && DEVICE=hdc || DEVICE=sr0
  
mount -t iso9660 /dev/\$DEVICE /mnt
  
if [ -f /mnt/context.sh ]; then
  . /mnt/init.sh
fi
  
umount /mnt
  
EOF

# Make sure to change the permissions for the script so
# that it is executable.
chmod 0755 /mnt/usr/bin/onecontext


# Execute the contextualization at the end of the startup sequence.
cat > /mnt/etc/rc.d/rc.startup/95.context <<EOF
#!/bin/sh
. /usr/bin/onecontext
EOF
chmod 0755 /mnt/etc/rc.d/rc.startup/95.context

# Unmount the disk and powerdown the machine.
umount /mnt
shutdown -h
