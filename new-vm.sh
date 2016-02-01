#!/bin/bash
#

VMHOSTNAME="<NAME OF GOLDEN HOST>"
VMPATH="<PATH TO VM IMAGES>"
DHCPDFILE="/etc/dhcp/dhcpd.conf"

if [ -z "$1" ];
then
        echo "Usage: new-vm.sh <hostname>";
else
        echo $1
        # You cannot "clone" a running vm, stop it.  suspend and destroy
        # are also valid options for less graceful cloning
        virsh shutdown $VMHOSTNAME
        
        virsh destroy $1
        virsh undefine $1

        # copy the storage.
        echo "Copying image..."
        sudo rsync -aP $VMPATH/$VMHOSTNAME.qcow2 $VMPATH/$1.qcow2
        
        # dump the xml for the original
        echo "Dumping XML..."
        virsh dumpxml $VMHOSTNAME > /tmp/$1.xml
        
        virsh start $VMHOSTNAME

        # hardware addresses need to be removed, libvirt will assign
        # new addresses automatically
        echo "Checking for dhcp definition"
        if [ "`grep $1 $DHCPDPATH`" != "" ];
        then
                MAC="`grep -A1 $1 $DHCPDPATH|grep -v $1|awk '{print $3}'|sed -e 's/;$//'`"
                sed -i -e "s/..:..:..:..:..:../${MAC}/" /tmp/$1.xml
        fi
        
        # and actually rename the vm: (this also updates the storage path)
        sed -i -e "s/$VMHOSTNAME/$1/" /tmp/$1.xml
        sed -i /uuid/d /tmp/$1.xml

        if [ ! -d /mnt/loopback ];
        then
                sudo mkdir /mnt/loopback 
        fi
        echo "Clean up stale mounted...."
        sudo umount /mnt/loopback
        sudo modprobe nbd max_part=63
        sudo qemu-nbd -c /dev/nbd0 $VMPATH/$1.qcow2
        sudo mount /dev/nbd0p1 /mnt/loopback
        echo "Fixing hostname"
        sudo sed -i -e "s/$VMHOSTNAME/$1/" /mnt/loopback/etc/hosts
        sudo sed -i -e "s/$VMHOSTNAME/$1/" /mnt/loopback/etc/hostname
        sudo umount /mnt/loopback
        sudo qemu-nbd -d /dev/nbd0
        sudo rmmod nbd
        
        # finally, create the new vm
        echo "Importing $1's definition"
        virsh define /tmp/$1.xml
        #virsh start $VMHOSTNAME
        echo "Starting $1"
        virsh start $1
        

fi
