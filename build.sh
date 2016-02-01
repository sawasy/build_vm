#!/bin/bash

WORKPATH="<SOME DIRECTORY>"
# Pick a fast mirror close to you!
RSYNCSERVER="archive.ubuntu.mirror.rafal.ca"
CDSERVER="mirror.it.ubc.ca/ubuntu-releases"
RELEASE="14.04"
ARCH="amd64"

# Path to a local webserver for Packer to get the preseed.txt file from
WWWPATH="/var/www/html"

VMPATH="<WHERE YOUR VMS LIVE>"
VMHOST="<GOLDEN HOSTS NAME"
IMG="$VMPATH/$VMHOST.img"
MAC="<GOLDEN HOSTS MAC FROM YOUR DHCPD>"

PACKER_LOG="true"
PACKER_LOG_PATH="`pwd`"

#-----------

echo "++++++++ Downloading MD5 hash ++++++++"
/usr/bin/wget -O $WORKPATH/$RELEASE-$ARCH-MD5SUMS http://$CDSERVER/$RELEASE/MD5SUMS

MD5=`grep "server-$ARCH.iso" $WORKPATH/$RELEASE-$ARCH-MD5SUMS`
MD5HASH=`echo $MD5 |awk '{print $1}'`
FILE=`echo $MD5 |awk '{print $2}' |sed -e 's/\*//g' -e 's/\.iso//g'`
echo "$MD5HASH *$WORKPATH/$FILE.iso"  > $WORKPATH/$FILE.md5

if [ ! -f $WORKPATH/$FILE.iso ];
then
    /usr/bin/wget -O $WORKPATH/$FILE.iso http://$CDSERVER/$RELEASE/$FILE.iso
fi


echo "++++++++ Checking MD5... ++++++++"
md5sum --status -c $WORKPATH/$FILE.md5
if [ $? -ne 0 ];
then
    echo "MD5 doesn't match Exit non-zero. Downloading"
    /usr/bin/wget -O $WORKPATH/$FILE.iso http://$CDSERVER/$RELEASE/$FILE.iso
    md5sum --status -c $WORKPATH/$FILE.md5
    if [ $? -ne 0 ];
    then
        echo "Something is really wrong. MD5 still doesn't match. Exiting..."
        exit 1
    fi
fi

if [ -n "`diff preseed.txt $WWWPATH/preseed.txt`" ];
then
    echo "++++++++ Preseed file in /var/www/html differs. Copying... ++++++++"
    sudo cp preseed.txt $WWWPATH/preseed.txt
fi

if [ -d output-ubuntu-$VMHOST ];
then
    echo "++++++++ Cleaning Previous Builds ++++++++"
    rm -rf output-ubuntu-$VMHOST/
fi

#You are using firewalls, right? RIGHT?
echo "++++++++ Allowing port 2228 on Firewall ++++++++"
sudo ufw allow from any to any port 2228

#Clean up previous runs
echo "++++++++ Cleaning previous runs /var/lib/jenkins/VMs ++++++++"
sudo rm -rf /var/lib/jenkins/VMs

#Uncomment this to run by hand.
#PACKER_LOG=1 packer build ubuntu-$RELEASE-server-$ARCH.json

