#!/bin/bash

# habilita proxy scks para a instalação
export http_proxy=socks5://192.168.99.1:11000
export https_proxy=socks5://192.168.99.1:11000

# instala pacotes básicos
yum install -y make bzip2 openssh-clients nano htop wget automake gcc cpp glibc-devel glibc-headers \
glibc-kernheaders glibc glibc-common libgcc zlib-devel openssl-devel readline-devel 

 yum install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct openssl

wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm 
rpm -ivh epel-release-latest-7.noarch.rpm

yum update -y


# configura o ssh para um login rápido
echo "UseDNS no" >>/etc/ssh/sshd_config

# configra a rede com um ip default para acesso em uma pós configuração
source /etc/sysconfig/network-scripts/ifcfg-enp0s3 
cat >/etc/sysconfig/network-scripts/ifcfg-enp0s3  <<EOL
# Generated by dracut initrd
NAME=enp0s3
DEVICE=enp0s3
ONBOOT=yes
NETBOOT=yes
UUID=$UUID
IPV6INIT=yes
BOOTPROTO=none
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
IPADDR=192.168.1.2
PREFIX=24
GATEWAY=192.168.1.1
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
EOL