#!/bin/bash

source functions.sh

cd packer

file="$(pwd)/output-iso-base/centos-7-x86_64-base.ovf"
if [ -f "$file" ]
then
	print 100 "   [OK] - máquina centos-7-base já existe."
else
	print 100 "   [OK] - máquina centos-7-base não existe, criando máquina."
    packer build --force centos-7-base.json 
fi

file="$(pwd)/output-iso-gateway/centos-7-x86_64-gateway.ovf"
if [ -f "$file" ]
then
	print 100 "   [OK] - máquina centos-7-gateway já existe."
else
	print 100 "   [OK] - máquina centos-7-gateway não existe, criando máquina."
    packer build --force centos-7-gateway.json &
fi