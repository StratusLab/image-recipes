#!/bin/sh -ex

export OS=CentOS
export OS_VERSION=6.3
export OS_ARCH=x86_64
export IMAGE_VERSION=1.0
export TYPE=base
export IMAGE_SIZE=5
export MAC_ADDRESS=0a:0a:86:9e:49:60
export NAME=centos

#clean from failed build
sudo su - root -c "rm -rf /etc/libvirt/qemu/$NAME*"

#restart libvirtd
sudo su - root -c "service libvirtd restart"

sudo su - root -c "virt-install --nographics --noautoconsole --accelerate --hvm --name $NAME --ram=2000 --disk $PWD/$OS-$OS_VERSION-$OS_ARCH-$TYPE-$IMAGE_VERSION.img,bus=ide,size=$IMAGE_SIZE --location=http://mirror.centos.org/centos/6/os/$OS_ARCH/ -x \"ks=http://$NODE_IP/centos-6-minimal-ks-1.0.cfg\" --network bridge=br0 --mac=$MAC_ADDRESS  --noreboot"

while [ -n "`sudo su - root -c "virsh list | grep $NAME"|| true`" ]; do 
  sleep 120 
done

### Install StratusLab client tools.
# Ensure that latest metadata and packages are used.
sudo yum clean all
sudo yum remove stratuslab-cli-user stratuslab-cli-sysadmin -y || true
# Create directory to hold packages.
sudo rm -Rf /tmp/pkg-cache
sudo mkdir -p /tmp/pkg-cache
# Download the required packages.
sudo yumdownloader --destdir=/tmp/pkg-cache stratuslab-cli-user stratuslab-cli-sysadmin
# Force installation without dependencies.
# Dependency on ldap is still needed.
sudo yum install -y python-ldap
sudo rpm --install --nodeps --force /tmp/pkg-cache/*.rpm


sudo su - root -c "cd $PWD ; stratus-build-metadata --disks-bus virtio --author=\"hudson builder\" --os=$OS --os-version=$OS_VERSION --os-arch=$OS_ARCH --image-version=$IMAGE_VERSION --comment=\"$OS  $OS_VERSION $TYPE image automatically created by hudson. Configured only with a root user. The firewall in the image is disabled, IPv6 is enabled, and SELinux disabled. Uses the standard StratusLab contextualization mechanisms. A swap volume is expected to be provided on /dev/vdb. \" --compression=gz $OS-$OS_VERSION-$OS_ARCH-$TYPE-$IMAGE_VERSION.img"

sudo su - root -c "stratus-generate-p12 --common-name=\"hudson builder\" --email=\"hudson.builder@stratuslab.eu\" -o $PWD/test.p12"

sudo su - root -c "cd $PWD ; stratus-upload-image --machine-image-origin --public --compress gz --marketplace-endpoint http://onehost-5.lal.in2p3.fr:8081 --pdisk-endpoint onehost-5.lal.in2p3.fr --pdisk-username test --pdisk-password test1122 --p12-cert=test.p12 --p12-password=XYZXYZ $OS-$OS_VERSION-$OS_ARCH-$TYPE-$IMAGE_VERSION.img"
