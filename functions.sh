#!/bin/bash

black=`tput setaf 0`
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`

bg_black=`tput setab 0`
bg_red=`tput setab 1`
bg_green=`tput setab 2`
bg_yellow=`tput setab 3`
bg_blue=`tput setab 4`
bg_magenta=`tput setab 5`
bg_cyan=`tput setab 6`
bg_white=`tput setab 7`
green=`tput setab 2`
reset=`tput sgr0`

function pad() {
    tam=${1:-0}
    i="0"
    while [ $i -lt $tam ]
    do
        forty="$forty "
        i=$(($i+1))
    done

    y=$2    
    y="${y:0:$tam}${forty:0:$(($tam - ${#y}))}"
    echo "$y"
}

function print() {
    y=$(pad "$1" "$2")
    echo "${bg_black}${yellow}${y}${reset}"
}

function error(){
    y=$(pad "$1" "$2")
    echo "${bg_red}${white}${y}${reset}"
}

function success(){
    y=$(pad "$1" "$2")
    echo "${bg_green}${white}${y}${reset}"
}

function create_gateway() {
    vboxmanage import packer/output-iso-gateway/centos-7-x86_64-gateway.ovf
    sleep 1

    vboxmanage modifyvm "centos-7-x86_64-gateway" --name=gateway \
    --nic1=intnet --intnet1=openshift \
    --nic2=hostonly --hostonlyadapter2=vboxnet0 --intnet2=none

     vboxmanage startvm gateway --type headless
}



function create_vm() {
    vboxmanage import packer/output-iso-base/centos-7-x86_64-base.ovf
    sleep 1

    vboxmanage modifyvm centos-7-x86_64-base --name=$1 \
      --nic1=intnet --intnet1=openshift \
      --memory=$2


    sleep 1
    vboxmanage startvm $1 --type headless

    while true
    do
    nc -z 192.168.1.2 22  > /dev/null
    if [ $? -eq 0 ]
    then
        echo "Your host is ready"
        break
    fi
    echo "aguardando connectividade ssh"
    sleep 1
    done

    cat >/tmp/script.sh  <<EOL
#!/bin/bash
nmcli con mod enp0s3 ipv4.method manual ipv4.addresses $3/24 ipv4.gateway 192.168.1.1 ipv4.dns 192.168.99.1 ipv4.dns-search cluster.nodes
nmcli con show enp0s3
systemctl restart systemd-hostnamed
systemctl restart network
EOL
    chmod +x /tmp/script.sh

    sshpass -p root scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no /tmp/script.sh root@192.168.1.2:/tmp 

    timeout 3 sshpass -p root ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t  root@192.168.1.2 "/tmp/script.sh"
    
    vboxmanage controlvm $1 poweroff soft

    sleep 1
    vboxmanage startvm $1 --type headless
}

function destroy_vm() {

    vboxmanage controlvm $1 poweroff

    while true
    do
    VBoxManage list vms | sed -r 's/^"(.*)".*$/\1/' | grep $1 
    if [ $? -eq 1 ]
    then
        break
    fi
    sleep 1
    vboxmanage unregistervm $1 --delete
    done

}


