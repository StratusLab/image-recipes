#!/bin/sh -x 

dd if=/dev/zero of=swap.img bs=1024 count=1000000
dd if=/dev/zero of=centos-6.2-x86_64-1.0.img bs=1024 count=5000000

virsh destroy centos62
virsh undefine centos62

virt-install \
  --ram 1000 \
  --hvm \
  --accelerate \
  --name=centos62 \
  --disk=centos-6.2-x86_64-1.0.img,bus=scsi \
  --disk=swap.img,bus=scsi \
  --mac="0a:0a:86:9e:49:e6" \
  --location=http://mirror.in2p3.fr/linux/CentOS/6.2/os/x86_64/ \
  -x "ks=http://loomis.web.cern.ch/loomis/centos-6.2-minimal-ks-1.0.cfg" \
  --noreboot

virsh undefine centos62

