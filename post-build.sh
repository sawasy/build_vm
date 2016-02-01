#!/bin/bash
#



VMHOSTNAME="<YOUR GOLDEN HOSTS NAME>"
VMPATH="<PATH TO VM IMAGES>"
IMG="$VMHOSTNAME.qcow2"
MAC="<MAC AS DEFINED IN YOUR DHCPD"
JENKINS_HOME="/var/lib/jenkins"
ANSIBLE_PATH="/var/lib/jenkins/jobs/Build_VM/workspace/playbooks"
EMAIL="<YOUR EMAIL ADDRESS>"


echo "++++++++ Removing port 2228 from firewall ++++++++"
sudo ufw delete allow from any to any port 2228

if [ "`virsh list |grep $VMHOSTNAME`" ];
then

    # You cannot "clone" a running vm, stop it.  suspend and destroy
    # are also valid options for less graceful cloning
    echo "++++++++ Destroying golden-build in virsh ++++++++"
    virsh destroy $VMHOSTNAME
fi


if [ "`virsh list --all |grep $VMHOSTNAME`" ];
then

    # You cannot "clone" a running vm, stop it.  suspend and destroy
    # are also valid options for less graceful cloning
    echo "++++++++ Undefining $VMHOSTNAME in virsh ++++++++"
    virsh undefine $VMHOSTNAME
fi

# copy the storage. THIS WILL BE CUSTOMIZED TO YOUR TASTE. 
echo "++++++++ Copying image ++++++++"
sudo rsync -aP $JENKINS_HOME/VMs/$IMG $VMPATH

echo "++++++++ Importing $VMHOSTNAME's definition ++++++++"

virt-install -d -r 2048 \
    --vcpus=2 \
    --network bridge=br0 \
    --mac=$MAC \
    --accelerate \
    --name=$VMHOSTNAME \
    --file=$VMPATH/$IMG \
    --os-type=linux \
    --graphics none \
    --noautoconsole \
    --import


echo "++++++++ deleting prevous keys ++++++++"

#ssh-keygen -R $VMHOSTNAME
#Bigger hammer
rm -v $JENKINS_HOME/.ssh/known_hosts

echo Adding key...
/usr/bin/ssh-keyscan -v -T 10 -H $VMHOSTNAME >> $JENKINS_HOME/.ssh/known_hosts

#echo "++++++++ Running golden-build playbook ++++++++"
#/usr/bin/ansible-playbook -i $ANSIBLE_PATH/hosts --limit=$VMHOSTNAME --diff $ANSIBLE_PATH/$VMHOSTNAME.yml

echo "Build complete." |mailx -s "Jenkins golden-build complete." $EMAIL
