#!/bin/bash


function create_gateway() {
    vboxmanage import packer/output-iso-gateway/centos-7-x86_64-gateway.ovf
    sleep 1

    vboxmanage modifyvm "centos-7-x86_64-gateway" --name=gateway \
    --nic1=intnet --intnet1=openshift \
    --nic2=hostonly --hostonlyadapter2=vboxnet0 --intnet2=none

     vboxmanage startvm gateway
}



function create_vm() {
    vboxmanage import packer/output-iso-base/centos-7-x86_64-base.ovf
    sleep 1

    vboxmanage modifyvm centos-7-x86_64-base --name=$1 \
      --nic1=intnet --intnet1=openshift \
      --memory=$2


    sleep 1
    vboxmanage startvm $1

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
    vboxmanage startvm $1
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


