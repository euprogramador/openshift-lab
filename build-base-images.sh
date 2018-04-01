#!/bin/bash

echo "criando a imagem de base para o ambiente...."
cd packer
packer build --force centos-7-base.json
#packer build --force centos-7-gateway.json

echo "imagens de base criadas."