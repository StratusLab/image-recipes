#!/bin/sh

set +x
if [ -z "$PDISK_USERNAME" -o -z "$PDISK_PASSWORD" ]; then
   echo "PDisk username/password should be defined with PDISK_USERNAME/PDISK_PASSWORD. Aborting!"
   exit 1
fi
set -xe


export OS=Debian
export OS_VERSION=7.0
export OS_ARCH=x86_64
export IMAGE_VERSION=1.0
export TYPE=base
export IMAGE_SIZE=5
export MAC_ADDRESS=0a:0a:86:9e:49:60
export NAME=debian
export DIST=sid

#clean from failed build
sudo su - root -c "rm -f /etc/libvirt/qemu/$NAME.xml"

#restart libvirtd
sudo su - root -c "service libvirtd restart"

sudo su - root -c "virt-install --nographics --noautoconsole --accelerate --hvm --name $NAME --ram=2000 --disk $PWD/$OS-$OS_VERSION-$OS_ARCH-$TYPE-$IMAGE_VERSION.img,bus=ide,size=$IMAGE_SIZE --location=http://ftp.debian.org/debian/dists/$DIST/main/installer-amd64/ -x \"auto=true priority=critical url=http://$NODE_IP/debian_stratus.preseed\" --network bridge=br0 --mac=$MAC_ADDRESS  --noreboot"



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

set +x
cmd="stratus-upload-image --machine-image-origin --public --compress gz --marketplace-endpoint http://marketplace.stratuslab.eu --pdisk-endpoint pdisk.lal.stratuslab.eu --p12-cert=test.p12 --p12-password=XYZXYZ $OS-$OS_VERSION-$OS_ARCH-$TYPE-$IMAGE_VERSION.img"
echo "Lanching: $cmd"
sudo su - root -c "cd $PWD ; $cmd --pdisk-username ${PDISK_USERNAME} --pdisk-password ${PDISK_PASSWORD}"
set -x

