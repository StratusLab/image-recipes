#!/bin/sh 
export OS=Fedora
export OS_VERSION=17
export OS_ARCH=x86_64
export IMAGE_VERSION=1.0
export TYPE=base
export IMAGE_SIZE=5
export MAC_ADDRESS=0a:0a:86:9e:49:60
export NAME=fedora

#clean from failed build
sudo su - root -c "rm -f /etc/libvirt/qemu/$NAME.xml"

#restart libvirtd
sudo su - root -c "service libvirtd restart"



sudo su - root -c "virt-install --nographics --noautoconsole --accelerate --hvm --name $NAME --ram=2000 --disk $PWD/$OS-$OS_VERSION-$OS_ARCH-$TYPE-$IMAGE_VERSION.img,bus=ide,size=$IMAGE_SIZE --location=http://mirrors.ircam.fr/pub/fedora/linux/releases/$OS_VERSION/Fedora/$OS_ARCH/os/ -x \"ks=http://$NODE_IP/fedora17_stratus.ks\" --network bridge=br0 --mac=$MAC_ADDRESS  --noreboot"


while [ -n "`sudo su - root -c "virsh list | grep $NAME"|| true`" ]; do 
  sleep 120 
done



sudo su - root -c "yum install -y --nogpgcheck stratuslab-cli-user stratuslab-cli-sysadmin"


sudo su - root -c "cd $PWD ; stratus-build-metadata --author=\"hudson builder\" --os=$OS --os-version=$OS_VERSION --os-arch=$OS_ARCH --image-version=$IMAGE_VERSION --comment=\"$OS  $OS_VERSION $TYPE image automatically created by hudson. Configured only with a root user. The firewall in the image is disabled, IPv6 is enabled, and SELinux disabled. Uses the standard StratusLab contextualization mechanisms. A swap volume is expected to be provided on /dev/sdb. \" --compression=gz $OS-$OS_VERSION-$OS_ARCH-$TYPE-$IMAGE_VERSION.img"

sudo su - root -c "stratus-generate-p12 --common-name=\"hudson builder\" --email=\"hudson.builder@stratuslab.eu\" -o $PWD/test.p12"

sudo su - root -c "cd $PWD ; stratus-upload-image -f --compress=gz --with-marketplace -U build -P build2934 --p12-cert=test.p12 --p12-password=XYZXYZ $OS-$OS_VERSION-$OS_ARCH-$TYPE-$IMAGE_VERSION.xml"
