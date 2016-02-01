#!/bin/bash
#

VMPATH="<PATH TO VMS>"

if [ -z "$1" ];
then
        echo "Usage: destory-vm.sh <hostname>";
else
        echo $1
        virsh destroy $1
        virsh undefine $1    
        sudo rm -rf $VMPATH/$1.img    
fi
